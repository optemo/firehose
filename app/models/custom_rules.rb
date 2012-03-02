
class RuleComingSoon < Customization
  @feature_name = 'comingSoon'
  @needed_features = ['preorderDate']
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
  @needed_features = ['displayDate', 'preorderDate']
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


# class RuleBestSeller < Customization
#   @feature_name = 'bestseller'
#   @product_type = 'F1127'
#   @needed_features = ['orders']
#   @rule_type = 'Binary'
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