class ScrapingRule < ActiveRecord::Base
  #Validation for remote_featurename, local_featurename
  validates :local_featurename,  :presence => true, :format => { :with => /^(\w|_)+$/}
  validates :remote_featurename, :presence => true
  validates :regex, :presence => true
  validates :product_type, :presence => true
  validates :rule_type, :presence => true
  validates :bilingual, :inclusion => { :in => [false] }, :unless => "rule_type == 'Categorical'"
  has_many :candidates
  has_many :scraping_corrections

  REGEXES = {"any" => ".*", "price" => "\d*(\.\d+)?", "imgsurl" => '^(.*)/http://www.bestbuy.ca\1', "imgmurl" => '^(.*)55x55(.*)/http://www.bestbuy.ca\1100x100\2', 'imglurl' => '^(.*)55x55(.*)/http://www.bestbuy.ca\1100x100\2', 'Not Avaliable' =>'(Information Not Available)|(Not Applicable)/0' }
  
  def self.scrape(ids,ret_raw = false,rules = [], multi = nil, to_show = false) #Can accept both one or more ids, whether to return the raw json
    #Return type: Array of candidates
    candidates = []
    translations = []
    ids = Array(ids) # [ids] unless ids.kind_of? Array
    rules_hash = get_rules(rules,multi)

    corrections = ScrapingCorrection.all
    ids.each do |bbproduct|
      raw_return = nil
      en_trans = {}
      fr_trans = {}
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
        rescue BestBuyApi::TimeoutError
          puts "TimeoutError"
          sleep 30
          retry
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
              parsed = nil
              r[:regex].each do |current_regex|
                begin
                  if current_regex[:sub]
                    #Replacement part of the regex (do a match first, since it's a two-part operation)
                    parsed_temp = current_text[current_regex[:reg]]
                    parsed_temp = parsed_temp.sub(current_regex[:reg],current_regex[:sub]) if parsed_temp
                  else
                    #Just match, not replacement
                    parsed_temp = current_text[current_regex[:reg]]
                  end
                rescue RegexpError
                  parsed_temp = "**Regex Error"
                end
                # If match was successful, continue on from loop
                unless parsed_temp.nil?
                  parsed = parsed_temp
                  break
                end
              end
              
              #Validation Tests
              parsed = "**LOW" if r[:rule].min && parsed && parsed.to_f < r[:rule].min
              parsed = "**HIGH" if r[:rule].max && parsed && parsed.to_f > r[:rule].max
              #debugger if r.rule_type == "Categorical" && !r.valid_inputs.blank? && !r.valid_inputs.split("*").include?(parsed)
              parsed = "**INVALID" if r[:rule].rule_type == "Categorical" && parsed && !r[:rule].valid_inputs.blank? && !r[:rule].valid_inputs.split("*").include?(parsed)
              
              delinquent = parsed.blank? || (parsed == "**LOW") || (parsed == "**HIGH") || (parsed == "**Regex Error") || (parsed == "**INVALID")
            end
            
            if r[:rule].bilingual && !to_show
              local_featurename = r[:rule].local_featurename
              if r[:rule].french
                trans = fr_trans
              else
                trans = en_trans
                candidates << Candidate.new(:parsed => parsed.try(:downcase), :raw => raw.to_s, :scraping_rule_id => r[:rule].id, :sku => bbproduct.id, :delinquent => delinquent, :scraping_correction_id => (corr ? corr.id : nil), :model => r[:rule].rule_type, :name => local_featurename)
              end

              if trans.has_key?(local_featurename) && !delinquent
                # Store the highest priority match only
                if r[:rule].priority < trans[local_featurename][1]
                  trans[local_featurename] = [parsed, r[:rule].priority]
                end
              elsif !delinquent
                trans[local_featurename] = [parsed, r[:rule].priority]
              end

            else
             # Save the new candidate
             candidates << Candidate.new(:parsed => parsed, :raw => raw.to_s, :scraping_rule_id => r[:rule].id, :sku => bbproduct.id, :delinquent => delinquent, :scraping_correction_id => (corr ? corr.id : nil), :model => r[:rule].rule_type, :name => r[:rule].local_featurename)
            end
          end
        end
        #Return the raw info only on the first pass
        raw_return = raw_info if language == "English" && ret_raw == true 
        if language == "French" && ret_raw == true
          raw_return["French Specs"] = raw_info["specs"]
          ret_raw = raw_return
        end
      end
      if en_trans.empty? && multi == true
        p "No english translations found for product #{bbproduct.id}. Please ensure each scraping rule needing a translation has an english version."
      else
        en_trans.each_pair do |lf, data|
          parsed = data.first
          key = "cat_option.#{lf}.#{parsed.gsub('.',',').downcase}"
          translations << ['en', key, parsed]
          if fr_trans.empty? && multi == true
            p "No french translations were found for product #{bbproduct.id}"
          else
            begin
              unless fr_trans[lf].nil? # Don't save a french translation if nothing is scraped
                translations << ['fr', key, fr_trans[lf][0]]
              #  if fr_trans[lf][1] != en_trans[lf][1]+1
              #    p "Product #{bbproduct.id} 's fr and en results are not scraped from the same rule for #{lf}. \nFrench priority: #{fr_trans[lf][1]}, English priority: #{en_trans[lf][1]}"
              #  end
              end
            rescue
              p "A french translation may have not been defined for product #{bbproduct.id} #{lf}, or its value is missing"
            end
          end
        end
      end
    end
    if ret_raw
      [translations, [candidates,ret_raw]]
    else
      [translations, candidates]
    end
  end
  
  def self.get_rules(rules, multi)
    # return rules with the regexp objects
    rules_hash = []
    rules = [rules] unless rules.class == Array #Create an array if necessary
    rules = ScrapingRule.find_all_by_product_type(Session.product_type_path) if rules.empty?
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
