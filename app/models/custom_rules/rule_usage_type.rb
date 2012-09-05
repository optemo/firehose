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
    possible_usage_types = possibleValues(usage_type_node, filter_name)
    usage = {} # hash of the usage type that applies to each sku: {sku => [usage_a, usage_b]}
    # get the list of categories for usage type
    # cache the value returned here using memcached, perhaps?
    possible_usage_types.each do |filter_value|
      skus = BestBuyApi.search_with_filter(usage_type_node, filter_name, filter_value)
      skus.each do |skus|
        if usage.has_key?(skus) 
          usage[skus] << filter_value
        else
          usage[skus] = [filter_value]
        end
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
      old_usage_types = BinSpec.find_by_sql("SELECT *  FROM `bin_specs` WHERE `product_id` = #{product.id} AND `name` REGEXP 'usageType'")
      unless usage_types.nil?
        usage_types_long = usage_types.map{|u| @feature_name + '_' + u.gsub(/\s/, '')}
        old_usage_types.select!{|type| !usage_types_long.include?(type.name)}
        # create or edit specs for usage types that are in the feed
        usage_types_long.each do |usage_label|
          spec = spec_class.find_or_initialize_by_product_id_and_name(product.id, usage_label)
          spec.value = true
          res_specs += [spec]
        end
      end
      old_usage_types.each{|spec| BinSpec.delete(spec)} # delete the existing usage types which are not in the feed
    end
    res_specs
  end
end
