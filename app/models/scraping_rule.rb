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
    ids.each do |bbproduct|
      raw_return = nil
      ["English","French"].each do |language|
        begin
          raw_info = BestBuyApi.product_search(bbproduct.id, true, language == "English")
        rescue BestBuyApi::RequestError
          #Try the request without including extra info
          begin
            raw_info = BestBuyApi.product_search(bbproduct.id,false, language == "English")
          rescue BestBuyApi::RequestError
            next
          end
        end
        unless raw_info.nil?
          #Insert category id spec
          raw_info["category_id"] = bbproduct.category
          corrections = ScrapingCorrection.find_all_by_product_id_and_product_type(bbproduct.id,Session.product_type)
          rules = ScrapingRule.find_all_by_product_type_and_active(Session.product_type, true)
          rules.each do |r|
            next unless (!r.french && language == "English") || (r.french && language=="French")
            #Traverse the hash hierarchy
            if r.remote_featurename[/specs\./]
              identifiers = r.remote_featurename.split(".")
              if raw_info["specs"]
                raw = raw_info["specs"].select do |spec|
                  debugger if spec.nil? || identifiers.nil?
                  spec["group"] == identifiers[1] && spec["name"] == identifiers[2]
                end.first
                raw = raw["value"] unless raw.nil?
              end
            else
              raw = raw_info[r.remote_featurename]
            end
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
                    parsed = parsed.sub(Regexp.new(regexstr[0..replace_i]),regexstr[replace_i+2..-1]) if parsed
                  else
                    #Just match, not replacement
                    parsed = current_text[Regexp.new(regexstr)]
                  end
                rescue RegexpError
                  parsed = "**Regex Error"
                end
                #If it fails the first Regex, it should return nothing
                current_text = parsed if !parsed.nil? || firstregex
                break if firstregex && current_text.nil?
                firstregex = false
              end
              parsed = current_text
              
              #Validation Tests
              parsed = "**LOW" if r.min && parsed && parsed.to_f < r.min
              parsed = "**HIGH" if r.max && parsed && parsed.to_f > r.max
              #debugger if r.rule_type == "cat" && !r.valid_inputs.blank? && !r.valid_inputs.split("*").include?(parsed)
              parsed = "**INVALID" if r.rule_type == "cat" && parsed && !r.valid_inputs.blank? && !r.valid_inputs.split("*").include?(parsed)
              
              delinquent = parsed.blank? || (parsed == "**LOW") || (parsed == "**HIGH") || (parsed == "**Regex Error") || (parsed == "**INVALID")
            end
            #Save the new candidate
            candidates << Candidate.new(:parsed => parsed, :raw => raw.to_s, :scraping_rule_id => r.id, :product_id => bbproduct.id, :delinquent => delinquent, :scraping_correction_id => (corr ? corr.id : nil))
          end
        end
        #Return the raw info only on the first pass
        raw_return = raw_info if language == "English" && ret_raw == true 
        if language == "French" && ret_raw == true
          raw_return["French Specs"] = raw_info["specs"]
          ret_raw = raw_return
        end
      end
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
