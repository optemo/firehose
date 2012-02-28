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
    features.each do |remote_feature|
      sr = ScrapingRule.find_by_remote_featurename_and_product_type(remote_feature, Session.product_type_path)
      spec_class = Customization.rule_type_to_class(sr.rule_type)
      local_features += [{spec_class => sr.local_featurename}]
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
  
  def Customization.compute_specs(skus, product_type)
    # get all the customizations applicable to this product_type
    rules = Customization.find_all_by_product_type(Session.product_type_path)
    results = {}
    # execute each of the rules
    rules.each do |rule|
      input_features = Customization.get_needed_features(rule.needed_features, product_type)
      rule_results = rule.compute(skus, input_features)
      spec_class = rule_results[0].class
      debugger
      results.has_key?(spec_class) ? results[spec_class] += rule_results : results[spec_class] = rule_results
    end
    results
  end
end

# class RulePreorder < Customization
#   @feature_name = 'preorder'
#   @needed_features = ['PreorderReleaseDate']
#   @product_type = 'F1127'
#   @rule_type = 'Binary'
#   
#   # This subclass inherits all the class methods of the parent
#   # Customization.all and self.all are equivalent
#   
#   def RulePreorder.compute(skus, input_features)
#     #Customization.product_type = @product_type
#     return []
#   end
# end

class RuleNew < Customization
  @feature_name = 'is_new'
  @product_type = 'F1127'
  @needed_features = ['DisplayStartDate', 'PreorderReleaseDate']
  @rule_type = 'Binary'
  
  
  # compute functionality:
  # for the needed_features, get their values from the DB :)
  # then execute the function's own computation for calculating the value
  # then *save* the value in the table represented by @rule_type, under name @feature_name
  def RuleNew.compute(skus, spec_features)
    specs_to_save = []
    print "Computing value for RuleNew and skus"
    print skus
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
        spec_row = table_name.find_by_product_id_and_name(pid, feature_name)
        if spec_row.nil?
          values += [nil]
        else
          values += [spec_row.value]
        end
      end
      # actual computation logic
      specs_to_save += [RuleNew.compute_feature(values)]
    end
    specs_to_save
  end

  def RuleNew.compute_feature(values)
    # assumption: the values are in the same order as the needed_features, but this doesn't matter for this rule
    # if either of the values (dates) are within 30 days of today, make a spec with a true value
    derived_value = values.inject(false) { |result,val| result or val.nil? ? false : (Date.today - Date.parse(val) <= 30) }
    spec_class = Customization.rule_type_to_class(@rule_type)
    spec = spec_class.find_or_initialize_by_product_id_and_name(pid, @feature_name)
    spec.value = derived_value
    spec
  end
end