class ScrapingRule < ActiveRecord::Base
  #Validation for remote_featurename, local_featurename
  validates :local_featurename,  :presence => true
  validates :remote_featurename, :presence => true
  validates :regex, :presence => true
  validates :product_type, :presence => true
  validates :rule_type, :presence => true
  has_many :candidates
  has_and_belongs_to_many :results
  
  def self.scrape(ids,ret_raw = false) #Can accept both one or more ids, whether to return the raw json
    #Return type: Array of candidates
    candidates = []
    ids = [ids] unless ids.kind_of? Array
    ids.each do |id|
      begin
        raw_info = BestBuyApi.product_search(id)
      rescue BestBuyApi::RequestError
        next
      end
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
            delinquent = false
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
            delinquent = parsed.blank? || (parsed == "**LOW") || (parsed == "**HIGH") || (parsed == "**Regex Error")
          end
          #Save the new candidate
          candidates << Candidate.new(:parsed => parsed, :raw => raw.to_s, :scraping_rule_id => r.id, :product_id => id, :delinquent => delinquent, :scraping_correction_id => (corr ? corr.id : nil))
        end
      end
      ret_raw = raw_info if ret_raw == true
    end
    if ret_raw
      [candidates,ret_raw]
    else
      candidates
    end
  end
  
  def self.rules_by_priority(data)
    # This function checks the data passed in to see if there are multiple remote features being put into a single remote feature.
    data.to_a.sort{|a,b| a[1]["rule"].priority <=> b[1]["rule"].priority}
  end
  
end
