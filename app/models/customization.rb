# TODO: add the capability for a subclass of customization to be set for several product_types
# right now setting it on the topmost FutureShop category

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
  
  def Customization.rule_type_to_class(type)
    case type
      when "Categorical" then CatSpec
      when "Continuous" then ContSpec
      when "Binary" then BinSpec
      when "Text" then TextSpec
    end
  end
  
  def Customization.compute_specs(pids)
    debugger
    # get all the customizations applicable to this product_type
    product_type = Session.product_type
    rules = Customization.find_all_by_product_type(Session.product_type_path)
    results = {}
    # execute each of the rules
    rules.each do |rule|
      if rule == RuleBestSeller
        rule_results = RuleBestSeller.group_computation(pids)
      else
        spec_features = rule.needed_features
        #spec_features = Customization.get_needed_features(rule.needed_features)
        rule_results = []
        # if an sku doesn't have a required spec value in the table, passing nil value to feature computation
        pids.each do |pid|
          values = []
          spec_features.each do |spec_feature|
            table_name = spec_feature.keys[0]
            feature_name = spec_feature.values[0]
            # This is only for DailySpecs orders
            if table_name == DailySpec
              spec_row = table_name.find_by_sku_and_name(Product.find(pid).sku, feature_name)
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
        results
        results.has_key?(spec_class) ? results[spec_class] += rule_results : results[spec_class] = rule_results
      end
    end
    debugger
    results
  end
end

class RuleBestSeller < Customization
  @feature_name = 'bestseller'
  @product_type = 'FDepartments'
  @needed_features = [{DailySpec => 'orders'}]
  @rule_type = 'Binary'

  def RuleBestSeller.group_computation(pids)
    today = Date.today # getting the weekday today
    lastFriday = Date.today - ((Date.today.wday - 5) % 7) # getting the date of the last friday, including today if friday
    
    weekly_orders = {}
    res_specs = []
    set = DailySpec.where(:name => 'orders', :date => (lastFriday..today)) # this set is inclusive!
    pids.each do |pid|
      prod = Product.find(pid) # will raise 
      raise 'attempting to re-add pid' unless weekly_orders[pid].nil?
      weekly_orders[pid] = set.where(:sku => prod.sku).inject(0) {|sum, spec| sum += spec.value_flt}
    end
    
    sorted_orders = weekly_orders.sort_by {|pid, sum| sum}
    sorted_orders.reverse!
    
    index = (sorted_orders.count * 0.2).to_i
    threshold = sorted_orders[index][1]
    
    top_20 = sorted_orders.select{|pid,val| (val >= threshold and val > 0)}
    bottom_80 = sorted_orders.select{|pid,val| (val < threshold or val == 0)}
    spec_class = Customization.rule_type_to_class(@rule_type)
    
    top_20.each do |pid, sum|
      spec = spec_class.find_or_initialize_by_product_id_and_name(pid, @feature_name)
      spec.value = 1
      res_specs += [spec]
    end
    bottom_80.each do |pid, sum|
      prod = Product.find(pid)
      spec = spec_class.find_by_product_id_and_name(pid, @feature_name)
      spec_class.delete(spec) unless spec.nil?
    end
    res_specs
  end
end

class RuleComingSoon < Customization
  @feature_name = 'comingSoon'
  @needed_features = [{CatSpec => 'preorderReleaseDate'}]
  @product_type = 'FDepartments'
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
  @product_type = 'FDepartments'
  @needed_features = [{CatSpec => 'displayDate'}, {CatSpec => 'preorderReleaseDate'}]
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
  @feature_name = 'onsale'
  @product_type = 'FDepartments'
  @needed_features = [{CatSpec => 'saleEndDate'}]
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

