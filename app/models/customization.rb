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
  
  def Customization.compute_specs(skus, product_type)
    # get all the customizations applicable to this product_type
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

class RuleComingSoon < Customization
  @feature_name = 'comingSoon'
  @needed_features = ['preorderDate']
  @product_type = 'F1127'
  @rule_type = 'Binary'
  
  def RuleComingSoon.compute_feature(values, pid)
    preoder_val = values[0]
    return nil if preoder_val == nil
    derived_value = (Date.parse(preoder_val) - Date.today > 0)
    #derived_value = values.inject(false) { |result,val| result or val.nil? ? false : (Date.today - Date.parse(val) <= 30) }
    spec_class = Customization.rule_type_to_class(@rule_type)
    # if the value is false, we don't want to return (and store) a spec, we want to delete it, so do it here
    spec = nil
    if derived_value == false
      spec = spec_class.find_by_product_id_and_name(pid, @feature_name)
      spec_class.delete(spec) unless spec.nil?
    else
      spec = spec_class.find_or_initialize_by_product_id_and_name(pid, @feature_name)
      spec.value = derived_value
    end
    spec
  end
end

class RuleNew < Customization
  @feature_name = 'isNew'
  @product_type = 'F1127'
  @needed_features = ['displayDate', 'preorderDate']
  @rule_type = 'Binary'
  # compute functionality:
  # for the needed_features, get their values from the DB
  # then execute the function's own computation for calculating the value
  # then *save* the value in the table represented by @rule_type, under name @feature_name
  # def RuleNew.compute(skus, spec_features)
  # 
  #   
  #   specs_to_save
  # end

  def RuleNew.compute_feature(values, pid)
    # assumption: the values are in the same order as the needed_features, but this doesn't matter for this rule
    # if either of the values (dates) are within 30 days of today, make a spec with a true value
    derived_value = values.inject(false) { |result,val| result or val.nil? ? false : (Date.today - Date.parse(val) <= 30) }
    spec_class = Customization.rule_type_to_class(@rule_type)
    # if the value is false, we don't want to return (and store) a spec, we want to delete it, so do it here
    spec = nil
    if derived_value == false
      spec = spec_class.find_by_product_id_and_name(pid, @feature_name)
      spec_class.delete(spec) unless spec.nil?
    else
      spec = spec_class.find_or_initialize_by_product_id_and_name(pid, @feature_name)
      spec.value = derived_value
    end
    spec
  end
end

class RuleOnsale < Customization
  @feature_name = 'newonsale'
  @product_type = 'F1127'
  @needed_features = ['saleEndDate']
  @rule_type = 'Binary'

  def RuleOnsale.compute_feature(values, pid)
    # if either of the values (dates) are within 30 days of today, make a spec with a true value
    val = values[0]
    return nil if val == nil
    derived_value = (Time.parse(val) - 4.hours) > Time.now
    spec_class = Customization.rule_type_to_class(@rule_type)
    # if the value is false, we don't want to return (and store) a spec, we want to delete it, so do it here
    spec = nil
    if derived_value == false
      spec = spec_class.find_by_product_id_and_name(pid, @feature_name)
      spec_class.delete(spec) unless spec.nil?
    else
      spec = spec_class.find_or_initialize_by_product_id_and_name(pid, @feature_name)
      spec.value = derived_value
    end
    spec
  end
end


# class RuleBestseller < Customization
#   @feature_name = 'bestseller'
#   @product_type = 'F1127'
#   @needed_features = ['orders']
#   @rule_type = 'Binary'
#   # compute functionality:
#   # for the needed_features, get their values from the DB
#   # then execute the function's own computation for calculating the value
#   # then *save* the value in the table represented by @rule_type, under name @feature_name
#   # def RuleNew.compute(skus, spec_features)
#   # 
#   #   
#   #   specs_to_save
#   # end
# 
#   def RuleNew.compute_feature(values, pid)
#     # assumption: the values are in the same order as the needed_features, but this doesn't matter for this rule
#     # if either of the values (dates) are within 30 days of today, make a spec with a true value
#     derived_value = (values[0] > 1)
#     spec_class = Customization.rule_type_to_class(@rule_type)
#     # if the value is false, we don't want to return (and store) a spec, we want to delete it, so do it here
#     spec = nil
#     if derived_value == false
#       spec = spec_class.find_by_product_id_and_name(pid, @feature_name)
#       spec_class.delete(spec) unless spec.nil?
#     else
#       spec = spec_class.find_or_initialize_by_product_id_and_name(pid, @feature_name)
#       spec.value = derived_value
#     end
#     spec
#   end
# end