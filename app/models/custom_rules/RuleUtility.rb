class RuleUtility < Customization
  @feature_name = 'utility'
  @product_type = ["B20218"]
  @needed_features = []
  @rule_type = 'Continuous'
  
  def RuleUtility.compute_utility(pids)
    
      cont_activerecords = [] # For bulk insert/update
      records = {}
      feature_value= 0;
      features=[]
      br_flag = FALSE
      has_brand = FALSE
      default = FALSE
      
      all_products = Product.where(["id IN (?) and instock = ?", pids, 1])
      prices ||= ContSpec.where(["product_id IN (?) and name = ?", all_products, "price"]).group_by(&:product_id)
      records["saleprice"] ||= ContSpec.where(["product_id IN (?) and name = ?", all_products, "saleprice"]).group_by(&:product_id)

      
      ptype_path = Session.product_type_path 
      #puts "path #{ptype_path}"
      ptype_path.each do |path|  
        default =TRUE if (path == ptype_path[0])  
        features = Facet.find_all_by_used_for_and_product_type("utility",path)
        break unless features.empty?
      end
   
      features.each do |f|
       has_brand = TRUE if f.name=~/^brand_/
       break if has_brand
      end    

      all_products.each do |product|
       utility = []
       br_flag=FALSE
       Maybe(features).each  do |f|
         puts "#{f.name}"
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
         #elsif (f.name == 'pageviews')
          # records[f.name] ||= DailySpec.where(["sku IN (?) and name = ? and date = ?", all_products, f.name, (Date.today-1)]).group_by(&:sku)
          # feature_value = records[f.name][product.sku].first.value if records[f.name][product.sku]
         else
           records[f.name] ||= model.where(["product_id IN (?) and name = ?", all_products, f.name]).group_by(&:product_id)
           if records[f.name][product.id]
             feature_value = records[f.name][product.id].first.value 
           
             if f.name == "displayDate"
               feature_value = RuleUtility.calculateFactor_displayDate(feature_value)
               feature_value = (1/feature_value)  if default
                puts "feature_value #{feature_value}"
             elsif f.name== "saleEndDate"
               feature_value = RuleUtility.calculateFactor_saleEndDate(feature_value)
             elsif f.feature_type == "Binary"
               feature_value = 1 if feature_value
             elsif f.feature_type == "Categorical"
               feature_value= 0
             end 
           end
         end
         feature_value = (feature_value + 1) if (feature_value > 0 && default)
         utility << (feature_value* (f.value))     
       end
        utility << (-2) if (!br_flag && has_brand) # The case that the product's brand is a new one and there is no coefficient for it in the facet table.
       #Add the static calculated utility 
       puts "#{utility}"
       utilities ||= ContSpec.where(["product_id IN (?) and name = ?", all_products, "utility"]).group_by(&:product_id)
       product_utility = utilities[product.id] ? utilities[product.id].first : ContSpec.new(product_id: product.id, name: "utility")
       product_utility.value = (utility.sum).to_f
        puts "product_id #{product.id} sku #{product.sku}  utility_sum #{utility.sum}"
       cont_activerecords << product_utility
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
    else
      ret = 0
    end
    ret
  end

end

