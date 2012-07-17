class RuleUtilityNew < Customization
  @feature_name = 'utility'
  @product_type = ["BDepartments", "FDepartments"]
  @needed_features = []
  @rule_type = 'Continuous'
  
  DEFAULT = 'utility'
  NON_DEFAULT = 'lr_utility'
  
  # The following array of hashes is used to tell the code what special methods should be called in which cases
  # The special method corresponds to the 'title' element of the hash (i.e. intercept corresponds to "intercept_value")
  # For a given feature, the code will see if it can 'match' an attribute of that feature 'with' the regular expression
  # If it can, it will call that method
  # Example 1: Element 1, intercept
  # => if feature.name =~ /Intercept/
  # =>  value = intercept_value
  # => end
  # Example 2: Element 8, categorical
  # => if feature.feature_type =~ /Categorical/
  # =>  value = categorical_value
  # => end
  COMPUTATION_METHODS = [ { 'title' => 'INTERCEPT',
                                  'match' => 'name', 'with' => 'Intercept' },
                            { 'title' => 'brand',
                                  'match' => 'name', 'with' => '^brand_' },
                            { 'title' => 'color',
                                  'match' => 'name', 'with' => '^color_' },
                            { 'title' => 'onsale_factor',
                                  'match' => 'name', 'with' => 'onsale_factor' },
                            { 'title' => 'display_date',
                                  'match' => 'name', 'with' => 'displayDate' },
                            { 'title' => 'sale_end_date',
                                  'match' => 'name', 'with' => 'saleEndDate' },
                            { 'title' => 'binary',
                                'match' => 'feature_type', 'with' => 'Binary' },
                            { 'title' => 'CATEGORICAL',
                                'match' => 'feature_type', 'with' => 'Categorical' }
                          ]
  
  # These constants are treated no different from the methods by the code
  INTERCEPT_value = 1
  CATEGORICAL_value = 0
  
  def RuleUtilityNew.group_computation(pids)
    # This array defines the default features. The coefficients will be calculated in this order.
    default_features = ['saleprice', 'averagePageviews', 'averageSales', 'displayDate', 'onsale_factor', 'isAdvertised']
    def_features_types = { 'saleprice' => 'Continuous', 'averagePageviews' => 'Continuous', 'averageSales' => 'Continuous', 'displayDate' => 'Categorical', 'onsale_factor' => 'Continuous', 'isAdvertised' => 'Binary' }

    # This array defines the features that don't have actual maximums and will be defined as 1.0 instead.
    features_without_max = ['onsale_factor', 'displayDate', 'isAdvertised']
    
    cached_data = {}
    cached_data['price'] = ContSpec.where(['product_id IN (?) and name = ?', pids, 'price']).group_by(&:product_id)
    
    created_utility_specs = {DEFAULT => [], NON_DEFAULT => []}
    
    # Get lr_utility features by working upwards through parents until features are found (but don't go all the way to the root; those features are already covered by utility)
    root_category = ProductCategory.where(retailer: Product.find(pids[0]).retailer, l_id: 1).first
    non_default_features = []
    ptype_path = Session.product_type_path
    ptype_path.reverse.each do |path|  
      non_default_features = get_features(path, DEFAULT) if (path != root_category.product_type)
      break unless non_default_features.empty?
    end
    
    # Compute the default coefficients that will be multiplied with feature values
    default_coefficients = compute_default_coefficients(default_features, def_features_types, features_without_max)
    
    for product_id in pids
      utility = 0
      for feature_name in default_features
        cached_data[feature_name] ||= Customization.rule_type_to_class(def_features_types[feature_name]).where('product_id IN (?) and name = ?', pids, feature_name).group_by(&:product_id)
        utility += get_feature_value(feature_name, product_id, DEFAULT, default_coefficients, cached_data)
      end
      utility /= 1e4
      created_utility_specs[DEFAULT] << ContSpec.new(product_id: product_id, value: utility, name: DEFAULT)
      
      if non_default_features.length > 0
        utility = 0
        found_brand = false
        for feature in non_default_features
          cached_data[feature.name] ||= Customization.rule_type_to_class(feature.feature_type).where('product_id IN (?) and name = ?', pids, feature.name).group_by(&:product_id)
          feature_value = get_feature_value(feature.name, product_id, NON_DEFAULT, default_coefficients, cached_data)
          if feature.name =~ /^brand_/ && feature_value != 0
            found_brand = true
          end
          utility += feature_value
        end
        utility -= 2 if !found_brand && feature_array_contains_regex?(non_default_features, 'name', /^brand_/i)
        created_utility_specs[NON_DEFAULT] << ContSpec.new(product_id: product_id, value: utility, name: NON_DEFAULT)
      end
    end
    
    return created_utility_specs
  end
  
  def RuleUtilityNew.get_feature_value( feature_name, product_id, feature_type, default_coefficients, cached_data )
  # This method checks what method to call based on the feature
    full_feature = Facet.find_by_name(feature_name)
    value = nil
    for method_data in COMPUTATION_METHODS
      # Get the regex we'll match with
      regex = Regexp.new(method_data['with'])
      # Derive the computation method name so we can call it
      method_name = "#{method_data['title']}_value"
      # Get what variable we're going to check the regex against (i.e. feature name, 'producer', etc.)
      feature_variable_to_compare = method_data['match']
      # If this is the feature we're dealing with, call the method to get the feature value
      if full_feature.instance_values['attributes'][feature_variable_to_compare] =~ regex
        # Evaluate the following statement. It may refer to a method or a constant; in either case get the value and assign it to tmp
        tmp = eval "#{method_name} product_id, feature_name, feature_type, cached_data" # Some or all of these parameters may be unnecessary
                                                                                        # but must be included for the ones that need it
        #tmp = RuleUtilityNew.method(method_name).call(product_id, feature_name, feature_type, cached_data)
        value = tmp.to_f if tmp
        break
      end
    end
    
    if value.nil? && cached_data[feature_name][product_id] # If this feature didn't have a special case but exists for this product
      value = cached_data[feature_name][product_id].first.value
    else
      value = 0
    end
    
    if feature_type == DEFAULT
      value += 1 if value > 0
      return value * default_coefficients[feature_name]
    end
    return value * full_feature.value
  end
  
  def RuleUtilityNew.get_features( product_type, used_for )
    return Facet.find_all_by_product_type_and_used_for(product_type, used_for)
  end
  
  def RuleUtilityNew.compute_default_coefficients( features, features_types, features_without_max )
  # Calculates the coefficients for the given features using the maximum values
  # If a feature doesn't have an actual maximum, 1.0 will be used instead.
    maximums = {}
    feature_index = 0
    while feature_index < features.length
      unless features_without_max.include?(features[feature_index])
        maximums[features[feature_index]] = Customization.rule_type_to_class(features_types[features[feature_index]]).maximum(:value, conditions: ['name = ?', features[feature_index]]).to_f || 0
      else
        maximums[features[feature_index]] = 1.0
      end
      feature_index += 1
    end
    maximums['averagePageviews'] = 11.0
    
    default_coefficients = { features.first => 10/maximums[features.first].to_f }
    feature_index = 1
    while feature_index < features.length
      default_coefficients[features[feature_index]] = ( maximums[features[feature_index-1]].to_f + 2) * default_coefficients[features[feature_index-1]].to_f
      feature_index += 1
    end
    return default_coefficients
  end
  
  # HELPER METHODS #
  private
  def RuleUtilityNew.feature_array_contains_regex?(array, attribute, regex)
    for element in array
      if element.instance_values['attributes'][attribute] =~ regex
        return true
      end
    end
    return false
  end
  
  def RuleUtilityNew.brand_value( product_id, feature_name, feature_type, cached_data )
    brand_spec = cached_data['brand'][product_id].first
    feature_brand_name = feature_name.gsub(/(^brand_)(.*)/, '\2').gsub('_', ' ').downcase
    if brand_spec && brand_spec.value.downcase == feature_brand_name
      #@found_brand = true
      return 1
    end
    return 0
  end
  
  def RuleUtilityNew.color_value( product_id, feature_name, feature_type, cached_data )
    color_spec = cached_data['color'][product_id].first
    feature_color_name = feature_name.split('_')[1].downcase
    if (color_spec && color_spec.value.downcase == feature_color_name) || feature_name == 'color_na'
      return 1
    end
    return 0
  end
  
  def RuleUtilityNew.onsale_factor_value( product_id, feature_name, feature_type, cached_data )
    original_price = cached_data['price'][product_id].first.value
    sale_price = cached_data['saleprice'][product_id].first.value
    return original_price > sale_price ? (original_price-sale_price)/(original_price) : 0
  end
  
  def RuleUtilityNew.display_date_value( product_id, feature_name, feature_type, cached_data )
    #debugger
    date_spec = cached_data['displayDate'][product_id]
    if date_spec
      date = Date.parse(date_spec.first.value)
      value = 0
      if Date.today > date
        value = Date.today - date
      end
      if feature_type == DEFAULT
        value = value == 0 ? 1 : 1/value
      end
      return value
    end
    return nil
  end
  
  def RuleUtilityNew.sale_end_date_value( product_id, feature_name, feature_type, cached_data )
    sale_date_spec = cached_data['saleEndDate'][product_id].first
    if sale_date_spec
      date = Date.parse(sale_date_spec.value)
      days_remaining = Date.today - date
      if days_remaining == 0
        return 1
      elsif days > 0
        return days_remaining
      end
      return 0
    end
    return nil
  end
  
  def RuleUtilityNew.binary_value( product_id, feature_name, feature_type, cached_data )
    if cached_data[feature_name][product_id]
      return 1
    end
    return nil
  end
end