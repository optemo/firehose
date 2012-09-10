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
  
  # Get list of candidate scraping rules to be applied for specified array of BBproduct instances.
  # Also gathers translations for categorical feature attributes.
  #
  # bb_products - Array of BBproduct instances.
  # ret_raw - Should we return raw data for debugging purposes?
  # rules - Rules to be applied. If empty, rules for the category will be retrieved from the database.
  # multi - Should we process local features with multiple rules? 
  #           true: process only local features with multiple rules.
  #           false: process only local features with a single rule.
  #           nil: process all local features, regardless of rule cardinality.
  # to_show - If true, disable translation gathering.
  #
  # Returns hash of {:translations, :candidates, :raw}.
  #   - translations: Array of arrays of form ['en'/'fr', key, parsed]. Key has form
  #                   "cat_option.<retailer>.<local feature name>.<English version of parsed value>". Duplicate entries may be returned.
  #                   It is also possible for multiple French translations to be returned with the same key.
  #   - candidates: Candidate scraping rules to be applied for the products provided. Multiple candidates may be returned for the same local 
  #                 feature, the decision about which candidate to apply in such cases is made later.
  #   - raw: If ret_raw is true, contains raw data returned by BestBuy API for the *first* product in the list provided.
  def self.scrape(bb_products, ret_raw = false, rules = [], multi = nil, to_show = false)
    bb_products = Array(bb_products)

    retailer_infos = []

    bb_products.each do |bb_product|
      sku = bb_product.id

      english_info = BestBuyApi.get_product_info(sku, true)
      english_info["category_id"] = bb_product.category unless english_info.nil?

      french_info = BestBuyApi.get_product_info(sku, false)
      french_info["category_id"] = bb_product.category unless french_info.nil?

      retailer_infos << RetailerProductInfo.new(sku, english_info, french_info)
    end

    apply_rules(retailer_infos, ret_raw, rules, multi, to_show)
  end

  # Get list of candidate scraping rules to be applied for specified array of product info hashes.
  # Also gathers translations for categorical feature attributes.
  #
  # product_infos - Array of RetailerProductInfo objects.
  #
  # For other arguments and return value, see documentation for scrape(), above.
  def self.apply_rules(product_infos, ret_raw = false, rules = [], multi = nil, to_show = false)
    candidates = []
    translations = []
    
    rules_hash = get_rules(rules,multi)

    if rules_hash.empty?
      return {translations: translations, candidates: candidates}
    end

    corrections = ScrapingCorrection.all
    product_infos.each do |product_info|
      raw_return = nil
      # We acquire translations of feature values for each product, duplicates are filtered later.
      en_trans = {}
      fr_trans = {}
      # For each product, we query both English and French product information.
      [:english, :french].each do |language|
        is_english = (language == :english)

        raw_info = product_info.get_info(language)

        unless raw_info.nil?
          rules_hash.each do |r|
            next unless (!r[:rule].french && is_english) || (r[:rule].french && !is_english)
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
            corr = corrections.find{|c|c.product_id == product_info.sku && c.scraping_rule_id == r[:rule].id && (c.raw == raw.to_s || c.raw == Digest::MD5.hexdigest(raw.to_s))}
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
              parsed = "**INVALID" if r[:rule].rule_type == "Categorical" && parsed && !r[:rule].valid_inputs.blank? && !r[:rule].valid_inputs.split("*").include?(parsed)
              
              delinquent = parsed.blank? || (parsed == "**LOW") || (parsed == "**HIGH") || (parsed == "**Regex Error") || (parsed == "**INVALID")
            end

            unless to_show || r[:rule].rule_type != "Categorical" #Only translate categorical features
              local_featurename = r[:rule].local_featurename
              trans = r[:rule].french ? fr_trans : en_trans
              # Store the translation and if it's already there only store the highest priority match
              if !delinquent && (!trans.has_key?(local_featurename) || r[:rule].priority < trans[local_featurename][1])
                trans[local_featurename] = [parsed, r[:rule].priority]
              end
            end
            if !(r[:rule].bilingual && !to_show && r[:rule].french) #Don't save data twice, so don't save it for french
              # Save the new candidate - if multi is true, we may save multiple candidates for the same local feature.
              # We will choose the one that actually gets applied later.
              candidates << Candidate.new(
                parsed: (r[:rule].local_featurename == "product_type" || r[:rule].rule_type != "Categorical" ? parsed : (parsed.nil? ? nil : CGI::escape(parsed.downcase))),
                raw: raw.to_s,
                scraping_rule_id: r[:rule].id,
                sku: product_info.sku,
                delinquent: delinquent,
                scraping_correction_id: (corr ? corr.id : nil),
                model: r[:rule].rule_type,
                name: r[:rule].local_featurename
              )
              #Note: we really should take product_type out of scraping_rules and hard code it
            end
          end
          #Return the raw info only on the first pass
          raw_return = raw_info if is_english && ret_raw == true 
          if !is_english && ret_raw == true
            raw_return["French Specs"] = raw_info["specs"]
            ret_raw = raw_return
          end
        end
      end
      if en_trans.empty?
        Rails.logger.debug "No english translations found for product #{product_info.sku}. Please ensure each scraping rule needing a translation has an english version." unless to_show
      else
        en_trans.each_pair do |lf, data|
          parsed = data.first
          key = "cat_option.#{Session.retailer}.#{lf}.#{CGI::escape(parsed.gsub('.','-').downcase)}"
          translations << ['en', key, parsed]
          begin
            unless fr_trans[lf].nil? # Don't save a french translation if nothing is scraped
              translations << ['fr', key, fr_trans[lf][0]]
            end
          rescue
            puts "A french translation may have not been defined for product #{product_info.sku} #{lf}, or its value is missing"
          end
        end
      end
    end
    {translations: translations, candidates: candidates, raw: ret_raw}
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
