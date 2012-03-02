class Customization
  class << self 
    attr_accessor :feature_name
    attr_accessor :needed_features
    attr_accessor :rule_type
    attr_accessor :product_type
  end
  
  def Customization.subclasses
      ObjectSpace.each_object(Class).select { |klass| klass < self }
  end
  
  def Customization.all
    Customization.subclasses
  end
  
  def Customization.find_all_by_product_type(product_types)
    product_types = [product_types] unless product_types.class == Array
    Customization.all.select{ |x| product_types.include?(x.product_type) }
  end
  
  def Customization.get_needed_features(features, product_type)
    # for each of the features,
    # look it up for the product type with ancestors under ScrapingRules.remote_featurename, find the local_featurename and rule_type
    # then according to the rule_type, go to one of the _specs tables and look up the feature value
    # then add the feature value to a hash by the original feature [name]
    local_features = []
    features.each do |local_feature|
      debugger
      sr = ScrapingRule.find_by_local_featurename_and_product_type(local_feature, Session.product_type_path)
      
      if sr.nil?
        # This is only for DailySpecs orders
        if local_feature == 'orders'
          spec_class = DailySpec
        else
          raise 'No scraping rule found matching feature ' + local_feature
        end
      else
        spec_class = Customization.rule_type_to_class(sr.rule_type)
      end
      local_features += [{spec_class => local_feature}]
    end
    local_features
  end
  
  def Customization.rule_type_to_class(type)
    case type
      when "Categorical" then CatSpec
      when "Continuous" then ContSpec
      when "Binary" then BinSpec
      when "Text" then TextSpec
    end
  end
  
  def Customization.compute_specs(skus)
    # get all the customizations applicable to this product_type
    product_type = Session.product_type
    rules = Customization.find_all_by_product_type(Session.product_type_path)
    results = {}
    # execute each of the rules
    rules.each do |rule|
      spec_features = Customization.get_needed_features(rule.needed_features, product_type)
      #rule_results = rule.compute(skus, spec_features)
      # RuleNew.compute(skus, spec_features)
      rule_results = []
      # assumption: there are scraping rules for the input features, and these have been scraped already
      # if an sku doesn't have a required spec value in the table, passing nil value to feature computation
      skus.each do |sku|
        # find the product id for this sku
        prod = Product.find_by_sku(sku)
        if prod.nil?
          # sku not found
          raise 'SKU ' + sku + ' not found in Products'
        end
        pid = prod.id
        values = []
        spec_features.each do |spec_feature|
          table_name = spec_feature.keys[0]
          feature_name = spec_feature.values[0]
          # This is only for DailySpecs orders
          if table_name == DailySpec
            spec_row = table_name.find_by_sku_and_name(sku, feature_name)
          else
            spec_row = table_name.find_by_product_id_and_name(pid, feature_name)
          end
          if spec_row.nil?
            values += [nil]
          else
            values += [spec_row.value]
          end
        end
        # actual computation logic
        spec = rule.compute_feature(values, pid)
        rule_results += [spec] unless spec.nil?
      end
      
      unless rule_results.empty?
        spec_class = rule_results[0].class
        results.has_key?(spec_class) ? results[spec_class] += rule_results : results[spec_class] = rule_results
      end
    end
    # debugger
    results
  end
end