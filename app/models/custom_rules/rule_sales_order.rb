class RuleSalesOrder < Customization
  @feature_name = 'salesOrder'
  @product_type = ['ADepartments']
  @needed_features = []
  @rule_type = 'Continuous'
  
  def RuleSalesOrder.group_computation( pids )
    #max_rank = ContSpec.maximum(:value, conditions: ['product_id IN (?) and name = ?', pids, 'sales_rank'])
    sales_ranks = ContSpec.where(['product_id IN (?) and name = ?', pids, 'sales_rank'])
    max_rank = sales_ranks.map(&:value).max
    sales_ranks = sales_ranks.group_by(&:product_id)
    
    specs = []
    
    for pid in pids
      sales_rank = sales_ranks[pid]
      unless sales_rank
        sales_rank = max_rank + 1
      else
        sales_rank = sales_rank.first.value
      end
      salesOrder = sales_rank/max_rank
      
      specs << ContSpec.new(product_id: pid, value: salesOrder, name: @feature_name)
    end
    
    specs
  end
end