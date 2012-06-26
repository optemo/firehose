class RuleUsageType < Customization
  @feature_name = 'usageType'
  @product_type = ['F1002']
  @needed_features = []
  @rule_type = 'Binary'
  
  def RuleUsageType.possibleValues(usage_type_node = '1002', filter_name = "Usage Type")
    BestBuyApi.get_filter_values(usage_type_node, filter_name)
  end
  
  def RuleUsageType.local_featureList
    possibleValues.map{ |v| @feature_name + '_' + v.gsub(/\s/, '')}.to_a
  end
  
  def RuleUsageType.group_computation(pids)
    usage_type_node = '1002'
    filter_name = "Usage Type"
    tries = 0
    begin
      usage = {} # hash of the usage type that applies to each sku: {sku => [usage_a, usage_b]}
      # get the list of categories for usage type
      # cache the value returned here using memcached, perhaps?
      possibleValues(usage_type_node, filter_name).each do |filter_value|
        skus = BestBuyApi.search_with_filter(usage_type_node, filter_name, filter_value)
        skus.each do |skus|
          if usage.has_key?(skus) 
            usage[skus] << filter_value
          else
            usage[skus] = [filter_value]
          end
        end
      end
    rescue BestBuyApi::RequestError => error
      tries += 1
      if tries <= 5
        puts 'Got BestBuy Api error, will retry 5 times'
        puts error.to_s
        retry
      else
        raise error
      end
    end
    # get the list of categories for usage type
    # overall data structure: hash indexed by sku
    # to build the hash, for each usage type value, go through the list of skus and add the usage type to the array for that sku
    # {sku => [usage_a, usage_b]}
    spec_class = Customization.rule_type_to_class(@rule_type)
    res_specs = []
    Product.find(pids).each do |product|
      usage_types = usage[product.sku]
      
      unless usage_types.nil?
        usage_types.each do |type|
          usage_label = @feature_name + '_' + type.gsub(/\s/, '')
          spec = spec_class.find_or_initialize_by_product_id_and_name(product.id, usage_label)
          spec.value = true
          res_specs += [spec]
        end
      end
    end
    res_specs
  end
end
