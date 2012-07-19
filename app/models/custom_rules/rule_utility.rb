class RuleUtility < Customization
  @feature_name = 'utility'
  @product_type = ["BDepartments", "FDepartments"]
  @needed_features = []
  @rule_type = 'Continuous'
  
  def RuleUtility.group_computation(pids)
    
      default ="utility"
      non_default = "lr_utility"
      cont_activerecords = Hash.new # For bulk insert/update
      cont_activerecords[default]=[]
      cont_activerecords[non_default]=[]
      records = {}
      feature_value= 0;
      feature_types =Hash.new
      #flag for checking if product's brand has a coefficient in the facet table
      br_flag = FALSE #flag for checking if product's brand has a coefficient in the facet table
      has_brand = FALSE
      
      all_products = Product.where(["id IN (?) and instock = ?", pids, 1])
      prices ||= ContSpec.where(["product_id IN (?) and name = ?", all_products, "price"]).group_by(&:product_id)
      records["saleprice"] ||= ContSpec.where(["product_id IN (?) and name = ?", all_products, "saleprice"]).group_by(&:product_id)
      
      ptype_path = Session.product_type_path 
      #puts"path #{ptype_path.reverse}"
    
      feature_types[default] = Facet.find_all_by_used_for_and_product_type("utility","BDepartments")
      lr_features= []
      ptype_path.reverse.each do |path|  
       lr_features = Facet.find_all_by_used_for_and_product_type("utility",path) if (path != "BDepartments" and path != "FDepartments")
        break unless lr_features.empty?
      end
      feature_types[non_default] = lr_features unless lr_features.empty?
      puts 'adding lr utility for ' + Session.product_type_path.to_s unless lr_features.empty?
      #compute coefficients for the default rule-based utility
      feature_types[default].each do |f|
        max= 0
        unless (f.name == 'onsale_factor' || f.name == 'displayDate' || f.name =="isAdvertised")  
         model = Customization.rule_type_to_class(f.feature_type)
         debugger if f.name == 'averagePageviews'
         max = model.maximum(:value, :conditions => ['name = ?', f.name])
         f.value = max.to_f if max
        else
          f.value = 1 #max value for onsale_factor and displayDate and isAdvertised
        end
      end
      
      feature_types[default] = calculate_default_coefs(feature_types[default])
      
      #check for brand if there is any non-default utility calculation
      Maybe(feature_types[non_default]).each do |f|
       has_brand = TRUE if f.name=~/^brand_/
       break if has_brand
      end    
      #go through utility calculation
      all_products.each do |product| 
       feature_types.each do |key,features|
         br_flag=FALSE
         utility = []  
         Maybe(features).each  do |f|
           feature_value = 0 
           model = Customization.rule_type_to_class(f.feature_type)
           if (f.name == "Intercept")
             feature_value =1 
           elsif (f.name =~ /^brand_/ || f.name =~ /^color_/)
             sp_feature = f.name.split("_")
             name = sp_feature[1]
             name = sp_feature[1]+" "+sp_feature[2] if (sp_feature.size == 3)
             records[sp_feature[0]] ||= model.where(["product_id IN (?) and name=? ", all_products,sp_feature[0]]).group_by(&:product_id)
             if records[sp_feature[0]][product.id]       
               if records[sp_feature[0]][product.id].first.value.downcase == name.downcase
                 feature_value = 1 
                 br_flag = TRUE if f.name=~/^brand_/
               end     
             elsif (f.name == "color_na")
               feature_value = 1
             end
           elsif (f.name == "onsale_factor")
             org_price = prices[product.id].first.value
             saleprice = records["saleprice"][product.id].first.value
             feature_value = RuleUtility.calculateFactor_sale(org_price, saleprice)
           else
             records[f.name] ||= model.where(["product_id IN (?) and name = ?", all_products, f.name]).group_by(&:product_id)
             if records[f.name][product.id]
               feature_value = records[f.name][product.id].first.value 
           
               if f.name == "displayDate"
                 feature_value = RuleUtility.calculateFactor_displayDate(feature_value)
                  if key == default 
                    feature_value = (1/feature_value) if feature_value != 0
                    feature_value = 1 if feature_value == 0
                  end 
               elsif f.name== "saleEndDate"
                 feature_value = RuleUtility.calculateFactor_saleEndDate(feature_value)
               elsif f.feature_type == "Binary"
                 feature_value = 1 if feature_value
               elsif f.feature_type == "Categorical"
                 feature_value= 0
               end 
             end
           end
           feature_value = (feature_value + 1) if (feature_value > 0 && key == default)
           utility << (feature_value* (f.value))     
         end
        
         utility << (-2) if (!br_flag && has_brand && key == non_default) # The case that the product has no brand or its brand is a new one, so there is no coefficient for it in the facet table.
         #Add the static calculated utility 
         #puts "#{utility}"
         utilities ||= ContSpec.where(["product_id IN (?) and name = ?", all_products, key]).group_by(&:product_id)
         product_utility = utilities[product.id] ? utilities[product.id].first : ContSpec.new(product_id: product.id, name: key)
         product_utility.value = (utility.sum).to_f
         product_utility.value = (product_utility.value/1e4) if key == default
          # puts "product_id #{product.id} sku #{product.sku} utility_name #{product_utility.name} utility_sum #{product_utility.value}"
         cont_activerecords[key] << product_utility
       end
      end
    #normalizing the default utility values  
     #cont_activerecords[default] = normalize(cont_activerecords[default])
    #print out put 
     
    # (cont_activerecords[default]+ cont_activerecords[non_default]).each do |product|
    #      puts "product_id #{product.product_id} utility_name #{product.name} utility_sum #{product.value}"
    # end
     cont_activerecords[default]+ cont_activerecords[non_default]
     
  end
  
  def self.map_range (cont_activerecords)
     values =[]
     cont_activerecords.inject(values){|values,ele| values << ele.value}
     a1 =  values.min
     a2 = values.max
     b1= -5
     b2=5
     m = (b2-b1)/(a2-a1)
     cont_activerecords.each do |row|
       row.value = b1 + (row.value - a1) * m
     end 
     cont_activerecords
  end
  
  def self.normalize(cont_activerecords)
    values =[]
    cont_activerecords.inject(values){|values,ele| values << ele.value}
    mean = (values.sum.to_f/values.size.to_f)
    sd =  values.inject(0){|res,ele| res + (ele-mean)**2}
    sd /= (values.size.to_f-1)
    sd = Math.sqrt(sd)
    cont_activerecords.each do |r|
      r.value = (r.value-mean).to_f/sd
    end
    cont_activerecords
  end
  def self.calculateFactor_sale(fVal1, fVal2) 
     fVal1 > fVal2 ? ((fVal1-fVal2)/fVal1) : 0
  end
  
  def self.calculateFactor_displayDate(fVal)
    ret = (Date.today - Date.parse(fVal))
    ret = 0 if ret < 0
    ret
  end
  
  def self.calculateFactor_saleEndDate(fVal)
    ret = (Date.parse(fVal) - Date.today)
    if ret>0
      ret = 1/ret
    elsif ret == 0
      ret = 1
    else
      ret = 0
    end
    ret
  end
  
  def self.calculate_default_coefs (features)
    max_f = Hash.new
    hash_f = Hash.new
    features.each do |ele| 
      max_f[ele.name] = ele.value
      hash_f[ele.name] = ele.value
    end
      hash_f['saleprice'] = (10/(max_f['saleprice']||1)) 
      hash_f['averagePageviews'] = ((max_f['saleprice']||1)+2) * (hash_f['saleprice'])
      hash_f['averageSales'] = ((max_f['averagePageviews']||1)+2) * hash_f['averagePageviews']
      hash_f['displayDate'] =  ((max_f['averageSales']||1)+2) * hash_f['averageSales'] 
      hash_f['onsale_factor'] = ((max_f['displayDate']||1)+2)*hash_f['displayDate'] # max of displayDate is 1
      hash_f['isAdvertised'] = ((max_f['onsale_factor']||1)+2)*hash_f['onsale_factor'] # max of onsale_factor is 1    
   
      features.each do |f|
        f.value = hash_f[f.name]
       # puts "#{f.name} f.value #{f.value}"
      end
    features
  end
    

end

