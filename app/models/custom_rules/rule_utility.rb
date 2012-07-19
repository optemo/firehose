class RuleUtility < Customization
  @feature_name = 'utility'
  @product_type = ["BDepartments", "FDepartments", "ADepartments"]
  @needed_features = []
  @rule_type = 'Continuous'
  
  DEFAULT = 'utility'
  NON_DEFAULT = 'lr_utility'
  
  ## The following array of hashes is used to tell the code what special methods should be called in which cases
  ## The special method corresponds to the 'title' element of the hash (i.e. intercept corresponds to "compute_value_for_intercept")
  ## For a given feature, the code will see if it can 'match' an attribute of that feature 'with' the regular expression
  ## If it can, then it knows that the feature has a special computation method and will call it
  ## Example 1: Element 1, intercept
  ## => if feature.name =~ /Intercept/
  ## =>  value = compute_value_for_intercept
  ## => end
  ## Example 2: Element 8, categorical
  ## => if feature.feature_type =~ /Categorical/
  ## =>  value = compute_value_for_categorical
  ## => end
  
  ## To add new special methods:
  ## 1. Add it to this hash.
  ## 2. Write the computation method (method name must be in the form 'compute_value_for_<title>').'
  ## => Make sure it behaves like the other methods do, returning a hash grouped by product ID containing the utility values for the products
  ## => (i.e. {'64' => '0.51351', '14444' => '0.78321'}, etc.)
  COMPUTATION_METHODS = [ { 'title' => 'intercept',
                                  'match' => 'name', 'with' => 'Intercept', 'for' => ['B', 'F'] },
                            { 'title' => 'brand',
                                  'match' => 'name', 'with' => '^brand_', 'for' => ['B', 'F'] },
                            { 'title' => 'color',
                                  'match' => 'name', 'with' => '^color_', 'for' => ['B', 'F'] },
                            { 'title' => 'onsale_factor',
                                  'match' => 'name', 'with' => 'onsale_factor', 'for' => ['B', 'F'] },
                            { 'title' => 'display_date',
                                  'match' => 'name', 'with' => 'displayDate', 'for' => ['B', 'F'] },
                            { 'title' => 'sale_end_date',
                                  'match' => 'name', 'with' => 'saleEndDate', 'for' => ['B', 'F'] },
                            { 'title' => 'binary',
                                'match' => 'feature_type', 'with' => 'Binary', 'for' => ['B', 'F'] },
                            { 'title' => 'categorical',
                                'match' => 'feature_type', 'with' => 'Categorical', 'for' => ['B', 'F'] },
                            { 'title' => 'sales_order',
                                'match' => 'name', 'with' => 'salesOrder', 'for' => ['A'] },
                          ]
  
  ## This array defines the default features. The coefficients will be calculated in this order.
  ## To add new default features just add them to the corresponding retailer's array.
  ## => Remember to keep them in the order the coefficients should be calculated in.
  DEFAULT_FEATURES =  { 'B' =>  [
                                  Facet.new(name: 'saleprice', feature_type: 'Continuous'),
                                  Facet.new(name: 'averagePageviews', feature_type: 'Continuous'),
                                  Facet.new(name: 'averageSales', feature_type: 'Continuous'),
                                  Facet.new(name: 'displayDate', feature_type: 'Categorical'),
                                  Facet.new(name: 'onsale_factor', feature_type: 'Continuous'),
                                  Facet.new(name: 'isAdvertised', feature_type: 'Binary')
                                ],
                        'F' =>  [
                                  Facet.new(name: 'saleprice', feature_type: 'Continuous'),
                                  Facet.new(name: 'averagePageviews', feature_type: 'Continuous'),
                                  Facet.new(name: 'averageSales', feature_type: 'Continuous'),
                                  Facet.new(name: 'displayDate', feature_type: 'Categorical'),
                                  Facet.new(name: 'onsale_factor', feature_type: 'Continuous'),
                                  Facet.new(name: 'isAdvertised', feature_type: 'Binary')
                                ],
                      }
  
  ## This array defines features without maximums; maximums will be considered to be 1.0 instead.
  FEATURES_WITHOUT_MAX =  { 'B' => ['onsale_factor', 'displayDate', 'isAdvertised'],
                            'F' => ['onsale_factor', 'displayDate', 'isAdvertised'],
                          }
  
  def RuleUtility.group_computation(pids)
    retailer = Product.find(pids[0]).retailer
    default_features = DEFAULT_FEATURES[retailer]
    features_without_max = FEATURES_WITHOUT_MAX[retailer]
    
    utility_specs = {DEFAULT => [], NON_DEFAULT => []}
    
    ## Get lr_utility features by working upwards through parents until features are found (but don't go all the way to the root; those features are already covered by utility)
    root_category = ProductCategory.where(retailer: retailer, l_id: 1).first
    non_default_features = []
    ptype_path = Session.product_type_path
    ptype_path.reverse.each do |path| 
      non_default_features = get_features(path, DEFAULT) if (path != root_category.product_type)
      break unless non_default_features.empty?
    end
    
    utilities = { DEFAULT => {}, NON_DEFAULT => {} }
    
    ## Compute the default coefficients that will be multiplied with feature values
    default_coefficients = compute_default_coefficients(default_features, features_without_max)
    ## Compute values for default utility
    for feature in default_features
      ## Get the values for all product IDs for this feature
      utilities[DEFAULT][feature.name] = get_feature_values(feature, pids, DEFAULT, retailer)
      ## Adjust the utility score with the coefficients
      utilities[DEFAULT][feature.name].each do |pid, utility|
        utility += 1 if utility > 0
        utilities[DEFAULT][feature.name][pid] = utility * default_coefficients[feature.name] / 1e4
      end
    end
    
    ## Compute lr utility values
    if non_default_features.length > 0
      ## Check if any of the features are brand features, i.e. brand_SONY, so that we can check later if a product matches any of them
      has_brand_features = false
      if non_default_features.find {|feature| /^brand_/ =~ feature.name}
        has_brand_features = true
      end
      for feature in non_default_features
        ## Get the values for all product IDs for this feature
        utilities[NON_DEFAULT][feature.name] = get_feature_values(feature, pids, NON_DEFAULT, retailer)
        ## Adjust the utility score with the precomputed coefficients from the database
        utilities[NON_DEFAULT][feature.name].each do |pid, utility|
          utilities[NON_DEFAULT][feature.name][pid] *= feature.value
          
          if has_brand_features && feature.name =~ /^brand_/
            ## If this is a brand feature, check if the current product's brand matches it.
            ## If it does (i.e. if compute_value_for_brand returned a value greater than 0), then the product's brand is not new.
            ## If it is new, however, subtract 2 from the utility score.
            new_brand = true
            new_brand = false if utilities[NON_DEFAULT][feature.name][pid] > 0
            utilities[NON_DEFAULT][feature.name][pid] -= 2 if new_brand
          end
        end
      end
    end
    
    ## Sum and return
    utilities.each do |utility_type, features|
      utility_values = {}
      features.each do |feature_name, feature_utilities|
        feature_utilities.each do |pid, utility|
          utility_values[pid] = 0 unless utility_values[pid]
          utility_values[pid] += utility
        end
      end
      ## Create specs
      utility_values.each do |pid, utility|
        utility_specs[utility_type] << ContSpec.new(product_id: pid, name: utility_type, value: utility)
      end
    end
    utility_specs[DEFAULT] + utility_specs[NON_DEFAULT]
  end
  
  def RuleUtility.get_feature_values( feature, pids, utility_type, retailer )
  ## This method checks what method to call based on the feature
    values = nil
    for method_data in COMPUTATION_METHODS
      next unless method_data['for'].include?(retailer)
      ## Get the method name, the feature variable we want to check, and the regular expression to check it against
      feature_variable_to_compare = method_data['match']
      method_name = "compute_values_for_#{method_data['title']}"
      regex = Regexp.new(method_data['with'])
      
      ## If this is the feature we're dealing with, call the method to get the feature value
      if feature.instance_values['attributes'][feature_variable_to_compare] =~ regex
        values = RuleUtility.method(method_name.to_sym).call(pids, feature.name, utility_type)
        break
      end
    end
    if values.nil?
      values = {}
      data = Customization.rule_type_to_class(feature.feature_type).where('product_id IN (?) and name = ?', pids, feature.name).group_by(&:product_id)
      for pid in pids
        if data[pid] ## If this feature didn't have a special case but exists for this product
          value = data[pid].first.value
        else
          value = 0
        end
        values[pid] = value
      end
    end
    values
  end
  
  def RuleUtility.get_features( product_type, used_for )
    return Facet.find_all_by_product_type_and_used_for(product_type, used_for)
  end
  
  def RuleUtility.compute_default_coefficients( features, features_without_max )
  ## Calculates the coefficients for the given features using the maximum values
  ## If a feature doesn't have an actual maximum, 1.0 will be used instead.
    maximums = {}
    feature_index = 0
    while feature_index < features.length
      unless features_without_max.include?(features[feature_index].name)
        maximums[features[feature_index].name] = Customization.rule_type_to_class(features[feature_index].feature_type).maximum(:value, conditions: ['name = ?', features[feature_index].name]).to_f || 0
      else
        maximums[features[feature_index].name] = 1.0
      end
      feature_index += 1
    end
    
    maximums['averagePageviews'] = 11.0 ## THIS IS WRONG! The original utility code makes use of this number because it exists in the database,
                                        ## => so I've included it here such that comparing the results of this code versus the old code is actually possible.
                                        ## It will be removed when sufficient testing has been done.
    
    default_coefficients = { features.first.name => 10/maximums[features.first.name].to_f }
    feature_index = 1
    while feature_index < features.length
      default_coefficients[features[feature_index].name] = ( maximums[features[feature_index-1].name].to_f + 2) * default_coefficients[features[feature_index-1].name].to_f
      feature_index += 1
    end
    return default_coefficients
  end
  
  ## HELPER METHODS ##
  private
  def RuleUtility.compute_values_for_brand( pids, feature_name, utility_type )
    data = CatSpec.where('product_id IN (?) and name = ?', pids, 'brand').group_by(&:product_id)
    brand_values = {}
    for pid in pids
      brand_spec = data[pid]
      feature_brand_name = feature_name.gsub(/(^brand_)(.*)/, '\2').gsub('_', ' ').downcase
      value = 0
      value = 1 if brand_spec && brand_spec.first.value.downcase == feature_brand_name
      brand_values[pid] = value
    end
    brand_values
  end
  
  def RuleUtility.compute_values_for_color( pids, feature_name, utility_type )
    data = CatSpec.where('product_id IN (?) and name = ?', pids, 'color').group_by(&:product_id)
    color_values = {}
    for pid in pids
      color_spec = data[pid]
      feature_color_name = feature_name.split('_')[1].downcase
      value = 0
      value = 1 if (color_spec && color_spec.first.value.downcase == feature_color_name) || feature_name == 'color_na'
      color_values[pid] = value
    end
    color_values
  end
  
  def RuleUtility.compute_values_for_onsale_factor( pids, feature_name, utility_type )
    prices = ContSpec.where('product_id IN (?) and name = ?', pids, 'price').group_by(&:product_id)
    saleprices = ContSpec.where('product_id IN (?) and name = ?', pids, 'saleprice').group_by(&:product_id)
    onsale_factor_values = {}
    for pid in pids
      original_price = prices[pid].first.value
      sale_price = saleprices[pid].first.value
      value = 0 
      value = (original_price-sale_price)/(original_price) if original_price > sale_price
      onsale_factor_values[pid] = value
    end
    onsale_factor_values
  end
  
  # def RuleUtility.compute_value_for_display_date( cached_data, product_id, feature_name, utility_type )
  #   date = Maybe(cached_data['displayDate'][product_id]).first.value
  #   value = Date.today - Date.parse(date) if date  ## in case of lr_utility we just return the difference 
  #   if utility_type == DEFAULT
  #     Date.today <= date ? value=1 : value=1/value ## in case of general utility we return the inverse of the difference 
  #   end
  #   value
  # end
  
  def RuleUtility.compute_values_for_display_date( pids, feature_name, utility_type )
    data = CatSpec.where('product_id IN (?) and name = ?', pids, 'displayDate').group_by(&:product_id)
    display_date_values = {}
    value = 0
    for pid in pids
      date_spec = data[pid]
      if date_spec
        days = Date.today - Date.parse(date_spec.first.value)
        case utility_type
        when DEFAULT
          if days > 0
            value = 1/days
          else
            value = 1
          end
        when NON_DEFAULT
          if days > 0
            value = days
          else
            value = 0
          end
        end
      end
      display_date_values[pid] = value
    end
    display_date_values
  end
  
  def RuleUtility.compute_values_for_sale_end_date( pids, feature_name, utility_type )
    data = CatSpec.where('product_id IN (?) and name = ?', pids, 'saleEndDate').group_by(&:product_id)
    sale_end_date_values = {}
    for pid in pids
      sale_date_spec = data[pid]
      value = 0
      if sale_date_spec
        date = Date.parse(sale_date_spec.first.value)
        days_remaining = Date.today - date
        if days_remaining == 0
          value = 1
        elsif days_remaining > 0
          value = days_remaining
        end
      end
      sale_end_date_values[pid] = value
    end
    sale_end_date_values
  end
  
  def RuleUtility.compute_values_for_binary( pids, feature_name, utility_type )
    data = BinSpec.where('product_id IN (?) and name = ?', pids, feature_name).group_by(&:product_id)
    binary_values = {}
    for pid in pids
      value = 0
      value = 1 if data[pid]
      binary_values[pid] = value
    end
    binary_values
  end
  
  def RuleUtility.compute_values_for_intercept( pids, feature_name, utility_type )
    intercept_values = {}
    for pid in pids
      intercept_values[pid] = 1
    end
    intercept_values
  end
  
  def RuleUtility.compute_values_for_categorical( pids, feature_name, utility_type )
    categorical_values = {}
    for pid in pids
      categorical_values[pid] = 0
    end
    categorical_values
  end
end
