class RulePriceplusehf < Customization
  @feature_name = 'pricePlusEHF'
  @needed_features = [{ContSpec => 'saleprice'}, {ContSpec => 'EHF'}]
  @product_type = ['BDepartments','FDepartments']
  @rule_type = 'Continuous'
  # Shallow update may update prices.
  @include_in_shallow_update = true
  
  def RulePriceplusehf.compute(values, pid)
    saleprice_val = values[0]
    ehf_val = values[1]
    spec = nil
    unless saleprice_val.nil?
      # set ehf to 0 in the odd case that it hasn't gotten scraped, to still compute a break the price plus ehf spec
      ehf_val ||= 0
      if ehf_val >= 0
        spec = Customization.rule_type_to_class(@rule_type).find_or_initialize_by_product_id_and_name(pid, @feature_name)
        spec.value = saleprice_val + ehf_val
      end
    end
    return spec
  end
end
