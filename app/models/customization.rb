
class Customization
  class << self 
    attr_accessor :feature_name
    attr_accessor :needed_features
    attr_accessor :rule_type
    attr_accessor :product_type
  end
  
  
  def Customization.subclasses
      [RuleNew]
      #ObjectSpace.each_object(Class).select { |klass| klass < self }
  end
  
  def Customization.all
    Customization.subclasses
  end
  
  def Customization.find_all_by_product_type(product_types)
    product_types = [product_types] unless product_types.class == Array
    Customization.all.select{ |x| product_types.include?(x.product_type) }
  end
  
  def Customization.get_needed_features(features)
    # look up the spec type of a feature for the product type with ancestors under ScrapingRules.local_featurename
    # and build an array of spec_class to feature name hashes
    local_features = []
    features.each do |local_feature|
      sr = ScrapingRule.find_by_local_featurename_and_product_type(local_feature, Session.product_type_path)
      if sr.nil?
        debugger
        raise 'No scraping rule found matching feature ' + local_feature
      else
        spec_class = Customization.rule_type_to_class(sr.rule_type)
      end
      # FIXME: remove this after adding a spec type to the custom rules
      spec_class = CatSpec if spec_class == ContSpec # this is because there are still date features that are continuous but we need categorical here
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
      debugger
      if rule == RuleBestSeller
        rule_results = RuleBestSeller.group_computation(skus)
      else
        spec_features = Customization.get_needed_features(rule.needed_features)
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

class RuleBestSeller < Customization
  @feature_name = 'bestseller'
  @product_type = 'F1127'
  @needed_features = ['orders']
  @rule_type = 'Binary'

  def RuleBestSeller.group_computation(skus)
    today = Date.today # getting the weekday today
    lastFriday = Date.today - (Date.today.wday - 5) # getting the date of the last friday, including today if friday
    weekly_orders = {}
    res_specs = []
    
    # get all the dates between today and last friday, including today and including last Friday
    # have a hash of sku->week_orders which stores the sum
    # the dates were changed here for testing
    td = Date.parse('2011-09-30')
    last = td - 6
    
    set = DailySpec.where(:name => 'orders', :date => (last..td)) # this set is inclusive!
    skus.each do |sku|
      raise 'attempting to re-add sku' unless weekly_orders[sku].nil?
      weekly_orders[sku] = set.where(:sku => sku).inject(0) {|sum, spec| sum += spec.value_flt}
    end
    
    sorted_orders = weekly_orders.sort_by {|sku, sum| sum}
    sorted_orders.reverse!
    
    index = (sorted_orders.count * 0.2).to_i
    threshold = sorted_orders[index][1]
    top_20 = sorted_orders.select{|sku,val| val >= threshold}
    spec_class = Customization.rule_type_to_class(@rule_type)
    
    top_20.each do |sku, sum|
      prod = Product.find_by_sku(sku)
      unless prod.nil?
        spec = spec_class.find_or_initialize_by_product_id_and_name(prod.id, @feature_name)
        spec.value = 1
        res_specs += [spec]
      end
    end
    res_specs
  end
  # def RuleNew.compute_feature(values, pid)
  #   # assumption: the values are in the same order as the needed_features, but this doesn't matter for this rule
  #   # if either of the values (dates) are within 30 days of today, make a spec with a true value
  #   derived_value = (values[0] > 1)
  #   spec_class = Customization.rule_type_to_class(@rule_type)
  #   # if the value is false, we don't want to return (and store) a spec, we want to delete it, so do it here
  #   spec = nil
  #   if derived_value == false
  #     spec = spec_class.find_by_product_id_and_name(pid, @feature_name)
  #     spec_class.delete(spec) unless spec.nil?
  #   else
  #     spec = spec_class.find_or_initialize_by_product_id_and_name(pid, @feature_name)
  #     spec.value = derived_value
  #   end
  #   spec
  # end
end

class RuleComingSoon < Customization
  @feature_name = 'comingSoon'
  @needed_features = ['preorderReleaseDate']
  @product_type = 'F1127'
  @rule_type = 'Binary'
  
  def RuleComingSoon.compute_feature(values, pid)
    preoder_val = values[0]
    return nil if preoder_val == nil
    derived_value = (Date.parse(preoder_val) - Date.today > 0)
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
  @needed_features = ['displayDate', 'preorderReleaseDate']
  @rule_type = 'Binary'

  def RuleNew.compute_feature(values, pid)
    # assumption: the values are in the same order as the needed_features, but this doesn't matter for this rule
    # if either of the values (dates) are within 30 days of today, make a spec with a true value
    derived_value = values.inject(false) { |result,val| result or val.nil? ? false : (Date.today >= Date.parse(val) and Date.today - Date.parse(val) <= 30) }
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

class RuleOnSale < Customization
  @feature_name = 'newonsale'
  @product_type = 'F1127'
  @needed_features = ['saleEndDate']
  @rule_type = 'Binary'

  def RuleOnSale.compute_feature(values, pid)
    val = values[0]
    return nil if val == nil
    # FIXME: don't we want when sale ends today, to still be on sale? used to be:
    # derived_value = (Time.parse(val) - 4.hours) > Time.now
    derived_value = (Date.parse(val) - Date.today >= 0)
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

# class RulePromoWeek < Customization
#   @feature_name = 'promoWeekOrders'
#   @product_type = 'F1127'
#   @needed_features = ['orders']
#   @rule_type = 'Continuous'
# 
# end

