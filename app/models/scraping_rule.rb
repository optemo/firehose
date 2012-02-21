class ScrapingRule < ActiveRecord::Base
  #Validation for remote_featurename, local_featurename
  validates :local_featurename,  :presence => true, :format => { :with => /^(\w|_)+$/}
  validates :remote_featurename, :presence => true
  validates :regex, :presence => true
  validates :product_type, :presence => true
  validates :rule_type, :presence => true
  has_many :candidates
  has_many :scraping_corrections

  REGEXES = {"any" => ".*", "price" => "\d*(\.\d+)?", "imgsurl" => '^(.*)/http://www.bestbuy.ca\1', "imgmurl" => '^(.*)55x55(.*)/http://www.bestbuy.ca\1100x100\2', 'imglurl' => '^(.*)55x55(.*)/http://www.bestbuy.ca\1100x100\2', 'Not Avaliable' =>'(Information Not Available)|(Not Applicable)/0' }
  
  def self.scrape(ids,ret_raw = false,rules = [], multi = nil) #Can accept both one or more ids, whether to return the raw json
    #Return type: Array of candidates
    candidates = []
    ids = Array(ids) # [ids] unless ids.kind_of? Array
    rules_hash = get_rules(rules,multi)
    corrections = ScrapingCorrection.all

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
            corr = corrections.find{|c|c.product_id == bbproduct.id && c.scraping_rule_id == r[:rule].id && (c.raw == raw.to_s || c.raw == Digest::MD5.hexdigest(raw.to_s))}
            if corr
              parsed = corr.corrected
              delinquent = false
            else
              #We can handle multiple passes of regular expressions with ^^
              current_text = raw.to_s
              firstregex = true
              r[:regex].each do |current_regex|
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
              #debugger if r.rule_type == "Categorical" && !r.valid_inputs.blank? && !r.valid_inputs.split("*").include?(parsed)
              parsed = "**INVALID" if r[:rule].rule_type == "Categorical" && parsed && !r[:rule].valid_inputs.blank? && !r[:rule].valid_inputs.split("*").include?(parsed)
              
              delinquent = parsed.blank? || (parsed == "**LOW") || (parsed == "**HIGH") || (parsed == "**Regex Error") || (parsed == "**INVALID")
            end
            #Save the new candidate
            candidates << Candidate.new(:parsed => parsed, :raw => raw.to_s, :scraping_rule_id => r[:rule].id, :sku => bbproduct.id, :delinquent => delinquent, :scraping_correction_id => (corr ? corr.id : nil), :model => r[:rule].rule_type, :name => r[:rule].local_featurename)
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
  
  def self.get_rules(rules, multi)
    # return rules with the regexp objects
    rules_hash = []
    rules = [rules] unless rules.class == Array #Create an array if necessary
    rules = ScrapingRule.find_all_by_product_type(Session.product_type_branch) if rules.empty?
    #Multi can be nil, true, or false
    # If nil, it will be ignored
    # If true it will only return candidates from multiple remote_featurenames for one local_featurename
    # If false it will only return candidates from local_featurenames with one remote_featurename
    unless multi.nil?
      groups = rules.group_by(&:local_featurename)
      rules = []
      groups.each_pair do |lf, grouped_rules|
        rules += grouped_rules if multi && grouped_rules.length > 1
        rules += grouped_rules if !multi && grouped_rules.length == 1
      end
    end
    rules.each do |r|
      # Generate the real regex
      rule_hash = {rule: r, regex: []}
      r.regex.split("^^").each do |current_regex|
        regexstr = current_regex.gsub(/^\//,"").gsub(/([^\\])\/$/,'\1')
        replace_i = regexstr.index(/[^\\]\//)
        if replace_i
          rule_hash[:regex] << {:reg=>Regexp.new(regexstr[0..replace_i]), :sub=>regexstr[replace_i+2..-1]}
        else
          rule_hash[:regex] << {:reg=>Regexp.new(regexstr)}
        end
      end

      # Generate the specs -- group and name
      if r.remote_featurename[/specs\./]
        identifiers = r.remote_featurename.split(".", 3)
        rule_hash[:specs] = {group: identifiers[1], name: identifiers[2]}
      end
      rules_hash << rule_hash
    end
    rules_hash
  end
  
end
