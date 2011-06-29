class ScrapingRule < ActiveRecord::Base
  #Validation for remote_featurename, local_featurename
  validates :local_featurename,  :presence => true
  validates :remote_featurename, :presence => true
  validates :regex, :presence => true
  validates :product_type, :presence => true
  validates :rule_type, :presence => true
  has_many :candidates

  REGEXES = {"any" => ".*", "price" => "\d*(\.\d+)?", "imgsurl" => '^(.*)/http://www.bestbuy.ca\1', "imgmurl" => '^(.*)55x55(.*)/http://www.bestbuy.ca\1100x100\2', 'imglurl' => '^(.*)55x55(.*)/http://www.bestbuy.ca\1100x100\2', 'Not Avaliable' =>'(Information Not Available)|(Not Applicable)/0' }

  def self.get_rules
    # return rules with the regexp objects
    rules_hash = []
    rules = ScrapingRule.find_all_by_product_type_and_active(Session.product_type, true)
    rules.each do |r|
      # Generate the real regex
      rule_hash = {}
      rule_hash.merge!({:rule=>r})
      rule = []
      r.regex.split("^^").each do |current_regex|
        regexstr = current_regex.gsub(/^\//,"").gsub(/([^\\])\/$/,'\1')
        replace_i = regexstr.index(/[^\\]\//)
        if replace_i
          rule << {:reg=>Regexp.new(regexstr[0..replace_i]), :sub=>regexstr[replace_i+2..-1]}
        else
          rule << {:reg=>Regexp.new(regexstr)}
        end
      end
      
      rule_hash.merge!({:real_regex=>rule})

      # Generate the specs -- group and name
      if r.remote_featurename[/specs\./]
        identifiers = r.remote_featurename.split(".")
        rule_hash.merge!({:specs=>{:group=>identifiers[1], :name=>identifiers[2]}})
      end
      rules_hash << rule_hash
    end
    rules_hash
  end
  
  def self.scrape(ids,ret_raw = false) #Can accept both one or more ids, whether to return the raw json
    #Return type: Array of candidates
    candidates = []
    ids = Array(ids) # [ids] unless ids.kind_of? Array
    rules_hash = get_rules

    ids.each do |bbproduct|
      raw_return = nil
      corrections = ScrapingCorrection.find_all_by_product_id_and_product_type(bbproduct.id,Session.product_type)
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

          rules_hash.each do |r|
            next unless (!r[:rule].french && language == "English") || (r[:rule].french && language=="French")
            #Traverse the hash hierarchy
            if r[:specs]
              if raw_info["specs"]
                raw = raw_info["specs"].find do |spec|
                  spec["group"] == r[:specs][:group] && spec["name"] == r[:specs][:name]
                end
                raw = raw["value"] unless raw.nil?
              end
            else
              raw = raw_info[r[:rule].remote_featurename]
            end
            corr = corrections.find{|c|c.scraping_rule_id == r[:rule].id && c.raw == raw.to_s}
            if corr
              parsed = corr.corrected
              delinquent = false
            else
              #We can handle multiple passes of regular expressions with ^^
              current_text = raw.to_s
              firstregex = true
              r[:real_regex].each do |current_regex|
                begin
                  if current_regex[:sub]
                    #Replacement part of the regex (do a match first, since it's a two-part operation)
                    parsed = current_text[current_regex[:reg]]
                    parsed = parsed.sub(current_regex[:reg],current_regex[:sub]) if parsed
                  else
                    #Just match, not replacement
                    parsed = current_text[current_regex[:reg]]
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
              parsed = "**LOW" if r[:rule].min && parsed && parsed.to_f < r[:rule].min
              parsed = "**HIGH" if r[:rule].max && parsed && parsed.to_f > r[:rule].max
              #debugger if r.rule_type == "cat" && !r.valid_inputs.blank? && !r.valid_inputs.split("*").include?(parsed)
              parsed = "**INVALID" if r[:rule].rule_type == "cat" && parsed && !r[:rule].valid_inputs.blank? && !r[:rule].valid_inputs.split("*").include?(parsed)
              
              delinquent = parsed.blank? || (parsed == "**LOW") || (parsed == "**HIGH") || (parsed == "**Regex Error") || (parsed == "**INVALID")
            end
            #Save the new candidate
            candidates << Candidate.new(:parsed => parsed, :raw => raw.to_s, :scraping_rule_id => r[:rule].id, :product_id => bbproduct.id, :delinquent => delinquent, :scraping_correction_id => (corr ? corr.id : nil))
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

  def self.cleanup
    ScrapingRule.joins('LEFT JOIN (select distinct scraping_rule_id from candidates) as c ON c.scraping_rule_id=scraping_rules.id').where('c.scraping_rule_id is null AND scraping_rules.active=false').destroy_all
  end
  
end
