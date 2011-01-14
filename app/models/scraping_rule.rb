class ScrapingRule < ActiveRecord::Base
  #Validation for remote_featurename, local_featurename
  validates :local_featurename,  :presence => true
  validates :remote_featurename, :presence => true
  validates :regex, :presence => true
  validates :product_type, :presence => true
  validates :rule_type, :presence => true
  has_many :candidates
  has_and_belongs_to_many :results
  
  def self.scrape(ids, inc_raw = false) #Can accept both one or more ids
    #Return type: [local_featurename][remote_featurename][]["products"] = [product_id,parsed,raw]
    #             [local_featurename][remote_featurename][]["rule"] = ScrapingRule
    #Four layer return type
    data = Hash.new{|h,k| h[k] = Hash.new{|i,l| i[l] = ScrapedResult.new}}
    ids = [ids] unless ids.kind_of? Array
    ids.each do |id|
      sleep 0.5 if defined? looped
      raw_info = BestBuyApi.product_search(id)
      unless raw_info.nil?
        corrections = ScrapingCorrection.find_all_by_product_id_and_product_type(id,Session.current.product_type)
        rules = ScrapingRule.find_all_by_product_type_and_active(Session.current.product_type, true)
        rules.each do |r|
          #Find content based on . seperated hierarchical description
          identifiers = r.remote_featurename.split(".")
          raw = raw_info
          #Traverse the hash hierarchy
          identifiers.each {|i| raw = raw[i] unless raw.nil?}
          raw = "" unless raw
          corr = corrections.select{|c|c.scraping_rule_id == r.id && c.raw == raw.to_s}.first
          if corr
            parsed = corr.corrected
          else
            #We can handle multiple passes of regular expressions with ^^
            current_text = raw.to_s
            firstregex = true
            r.regex.split("^^").each do |current_regex|
              regexstr = current_regex.gsub(/^\//,"").gsub(/([^\\])\/$/,'\1')
              replace_i = regexstr.index(/[^\\]\//)
              begin
                if replace_i
                  #Replacement part of the regex (do a match first, since it's a two-part operation)
                  parsed = current_text[Regexp.new(regexstr[0..replace_i])]
                  parsed = parsed.gsub(Regexp.new(regexstr[0..replace_i]),regexstr[replace_i+2..-1]) if parsed
                else
                  #Just match, not replacement
                  parsed = current_text[Regexp.new(regexstr)]
                end
                #Test for min / max
                parsed = "**LOW" if r.min && parsed && parsed.to_f < r.min
                parsed = "**HIGH" if r.max && parsed && parsed.to_f > r.max
                
              rescue RegexpError
                parsed = "**Regex Error"
              end
              #If it fails the first Regex, it should return nothing
              current_text = parsed if !parsed.nil? || firstregex
              firstregex = false
            end
            parsed = current_text
          end
          #Save the cleaned result
          data[r.local_featurename][r.id].add(r,ScrapedProduct.new(:id => id, :parsed => parsed, :raw => raw.to_s, :corrected => corr))
        end
        #Include raw json for other functionality
        data["RAW-JSON"] = raw_info if inc_raw
      end
      looped = true
    end
    #Convert to local_feature,remote_feature
    data.each do |lf,rules|
      data[lf] = rules.values.sort{|a,b|a.rule.priority <=> b.rule.priority} unless lf == "RAW-JSON"
    end
    data
  end
  
  def self.rules_by_priority(data)
    # This function checks the data passed in to see if there are multiple remote features being put into a single remote feature.
    data.to_a.sort{|a,b| a[1]["rule"].priority <=> b[1]["rule"].priority}
  end
  
end
