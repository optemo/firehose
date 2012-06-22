class RuleUsageType < Customization
  @feature_name = 'usageType'
  @product_type = ['F1002']
  @needed_features = []
  @rule_type = 'Categorical'

  def RuleUsageType.group_computation(pids)
    usage_type_node = '1002'
    filter_name = "Usage Type"
    tries = 0
    begin
      usage = {} # hash of the usage type that applies to each sku: {sku => [usage_a, usage_b]}
      # get the list of categories for usage type
      # cache the value returned here using memcached, perhaps?
      possible_values = BestBuyApi.get_filter_values(usage_type_node, filter_name)
      possible_values.each do |filter_value|
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
        usage_types.each do |usage_label|
          spec = spec_class.find_or_initialize_by_product_id_and_name_and_value(product.id, @feature_name, CGI::escape(usage_label))
          #spec.value = usage_label
          res_specs += [spec]
        end
      end
    end
    # save translations here
    translations = []
    
    possible_values_fr = BestBuyApi.get_filter_values(usage_type_node, "Type", 'fr')
    possible_values.each_with_index do |usage_label, index|
      key = "cat_option.#{Session.retailer}\.usageType\.#{CGI::escape(usage_label)}"
      en_value = usage_label
      fr_value = possible_values_fr[index]
      translations << ['en', key, en_value]
      translations << ['fr', key, fr_value]
    end
    
    translations.each do |locale, key, value|
      I18n.backend.store_translations(locale, {key => value}, {escape: false})
    end
    
    res_specs
  end
end
