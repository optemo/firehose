
class RuleOnSale < Customization
  @feature_name = 'onsale'
  @product_type = ['BDepartments', 'FDepartments']
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

