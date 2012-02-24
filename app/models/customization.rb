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
  
  def Customization.find_all_by_product_type(product_type)
    Customization.all.select{ |x| x.product_type == product_type }
  end
  
  def Customization.get_needed_features(features, product_type)
    # for each of the features,
    
    local_features = []
    features.each do |remote_feature|
    # look it up under ScrapingRules.remote_featurename, find the local_featurename and rule_type
      sr = ScrapingRule.find_by_remote_featurename_and_product_type(remote_feature, product_type)
      spec_class = case sr.rule_type
        when "Categorical" then CatSpec
        when "Continuous" then ContSpec
        when "Binary" then BinSpec
        when "Text" then TextSpec
      end
      local_features += [{spec_class => sr.local_featurename}]
    end
    # then according to the rule_type, go to one of the _specs tables and look up the feature value
    # then add the feature value to a hash by the original feature [name]
    local_features
  end
  
  def Customization.compute_specs(skus, product_type)
    # get all the customizations applicable to this product_type
    rules = Customization.find_all_by_product_type(product_type)
    results = []
    # for each of the rules, execute them on the skus
    rules.each do |rule|
      input_features = Customization.get_needed_features(rule.needed_features, product_type)
      results += rule.compute(skus, input_features)
    end
    # return all results group together
    return results
  end
  
end
class RulePreorder < Customization
  @feature_name = 'preorder'
  @needed_features = ['PreorderReleaseDate']
  @product_type = 'F1127'
  @rule_type = 'Binary'
  
  # This subclass inherits all the class methods of the parent
  # Customization.all and self.all are equivalent
  
  def RulePreorder.compute(skus, input_features)
    #Customization.product_type = @product_type
    p "should do the calculation here"
  end
end

class RuleNew < Customization
  @feature_name = 'new'
  @product_type = 'F1127'
  @needed_features = ['DisplayStartDate', 'PreorderReleaseDate']
  @rule_type = 'Binary'
  
  def RuleNew.compute(skus, spec_features)
    print "Computing value for RuleNew"
    # assumption: the input_features are in the specs tables; if they're not, throw error
    # check that release data < 30 days before today, or that display date < 30 days before today
    skus.each do |sku|
      # find the product id for this sku
      pid = Product.find_by_sku(sku).id # will throw error if sku not found ... can just check for nil? after find
      values = []
      spec_features.each do |spec_feature|
        table_name = spec_feature.keys[0]
        feature_name = spec_feature.values[0]
        debugger
        values += [table_name.find_by_product_id_and_name(pid, feature_name).value]
      end
      # now use the values to compute the derived feature value
    end
  end

  def RuleNew.compute_feature(values)
    # assumption: the values are in the same order as the needed_features
    derived_value = false
    displayStartDate_value = values[0]
    preorderReleaseDate_value = values[1]
    
    
  end

end

# compute functionality:
# for the needed_features, get their values from the DB :)
# then execute the function's own computation for calculating the value
# then *save* the value in the table represented by @rule_type, under name @feature_name