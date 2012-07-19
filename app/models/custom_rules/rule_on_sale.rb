class RuleOnSale < Customization
  @feature_name = 'onsale'
  @product_type = ['BDepartments', 'FDepartments', 'ADepartments']
  @needed_features = [{CatSpec => 'saleEndDate'}, {ContSpec => 'price'}, {ContSpec => 'saleprice'}]
  @rule_type = 'Binary'
  
  def RuleOnSale.compute(values, pid)
    date = values[0]
    rPrice = values[1]
    sPrice = values[2]
    
    if Session.retailer == 'A'
      derived_value = (rPrice - sPrice) >= 0.01
    else
      if date == nil
        derived_value = false
      else
        derived_value = (Date.parse(date) - Date.today >= 0) && (rPrice > sPrice)
      end
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

