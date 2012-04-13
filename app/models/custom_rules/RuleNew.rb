
class RuleNew < Customization
  @feature_name = 'isNew'
  @product_type = ['BDepartments','FDepartments']
  @needed_features = [{CatSpec => 'displayDate'}, {CatSpec => 'preorderReleaseDate'}]
  @rule_type = 'Binary'

  def RuleNew.compute_feature(values, pid)
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
