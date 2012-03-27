class RuleAverageSales < Customization
  @feature_name = 'averageSales'
  @product_type = ['BDepartments', 'FDepartments']
  @needed_features = [{DailySpec => 'online_orders'}]
  @rule_type = 'Continuous'

  def RuleAverageSales.group_computation(pids)
    days_back = 30
    yesterday = Date.today.prev_day
    date_range = (yesterday-days_back+1)..yesterday
    
    res_specs = []
    
    Product.find(pids).each do |product|
      # here, use the @needed_features key and value instead of hard-coding the names
      specs = DailySpec.where(:sku => product.sku, :name => "online_orders", :date => date_range)
      unless specs.empty?
        sales = 0
        days_instock = 0
        date_range.each do |day|
          prod = specs.select{|f| f.date == day}.first
          #Check in case the product order number does not exist in DailySpec for a particular day.
          if prod
            sales += prod.value_flt
            days_instock +=1
          end
        end
        
        if days_instock == 0
          avg_sales = 0
        else
          avg_sales = sales/days_instock
        end
        
        spec_class = Customization.rule_type_to_class(@rule_type)
        #Make a new orders row, unless the product already has one (update it then)
        spec = spec_class.find_or_initialize_by_product_id_and_name(product.id, @feature_name)
        spec.value = avg_sales
        res_specs += [spec]
      end
    end
    res_specs
  end
end
