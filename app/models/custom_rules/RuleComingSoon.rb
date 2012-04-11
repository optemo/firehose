class RuleComingSoon < Customization
  @feature_name = 'comingSoon'
  @needed_features = [{CatSpec => 'preorderReleaseDate'}]
  @product_type = ['BDepartments','FDepartments']
  @rule_type = 'Binary'
  
  def RuleComingSoon.compute_feature(values, pid)
    preoder_val = values[0]
    if preoder_val == nil
      derived_value = false
    else
      derived_value = (Date.parse(preoder_val) - Date.today > 0)
    end
    spec_class = Customization.rule_type_to_class(@rule_type)
    # if the value is false, we don't want to return (and store) a spec, we want to delete it, so do it here
    spec = nil
    if derived_value == false
      spec = spec_class.find_by_product_id_and_name(pid, @feature_name)
      spec_class.delete(spec) unless spec.nil?
      spec = nil
    else
      spec = spec_class.find_or_initialize_by_product_id_and_name(pid, @feature_name)
      spec.value = derived_value
    end
    spec
  end
end
