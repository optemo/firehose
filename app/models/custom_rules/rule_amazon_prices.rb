class RuleAmazonPrices < Customization
  @feature_name = 'price'
  @product_type = ['ADepartments']
  @needed_features = []
  @rule_type = 'Continuous'

  def RuleAmazonPrices.group_computation( pids )
    prices = ContSpec.where('product_id IN (?) and name = ?', pids, 'price').group_by(&:product_id)
    saleprices = ContSpec.where('product_id IN (?) and name = ?', pids, 'saleprice').group_by(&:product_id)
    
    specs = []
    
    for pid in pids
      price = prices[pid].first.value / 100.0
      saleprice = saleprices[pid].first.value / 100.0
      saleprice = price if saleprice > price
      price_spec = Customization.rule_type_to_class(@rule_type).find_or_initialize_by_product_id_and_name(pid, 'price')
      price_spec.value = price
      saleprice_spec = Customization.rule_type_to_class(@rule_type).find_or_initialize_by_product_id_and_name(pid, 'saleprice')
      saleprice_spec.value = saleprice
      specs << price_spec
      specs << saleprice_spec
    end
    specs
  end
end