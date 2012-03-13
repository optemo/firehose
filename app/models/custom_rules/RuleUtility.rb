class RuleUtility < Customization
  @feature_name = 'utility'
  @product_type = ['B20218']
  @rule_type = 'Continuous'
  
  def RuleUtility.compute_feature(pids)
    
      cont_activerecords = [] # For bulk insert/update
      records = {}
      pids_str = Array(pids).join(", ")
      feature_value= 0;
      all_products = Product.where(["id IN (?) and instock = ?", pids_str, 1])
      
      prices ||= ContSpec.where(["product_id IN (?) and name = ?", all_products, "price"]).group_by(&:product_id)
      saleprices||= ContSpec.where(["product_id IN (?) and name = ?", all_products, "saleprice"]).group_by(&:product_id)
      all_products.each do |product|
        utility = []
        Maybe(Session.features["utility"]).each do |f|
          puts "#{f.name}"
          feature_value = 0 
          model = Customization.rule_type_to_class(f.feature_type)
          if (f.name =~ [/^brand_*/] || f.name =~ [/^color_*/])
            sp_feature = f.name.split("_")
            puts "#{sp_feature}"
            records[sp_feature[1]] ||= model.where(["product_id IN (?) and name=? and value = ?", all_products,sp_feature[0], sp_feature[1]]).group_by(&:product_id)
            feature_value = 1 if records[sp_feature[1]][product.id]
          elsif (f.name == "onsale_factor")
            ori_price = prices[product.id]
            saleprice = saleprices[product.id]
            feature_value = RuleUtility.calculateFactor_sale(ori_price, sale_price)
          else
            records[f.name] ||= model.where(["product_id IN (?) and name = ?", all_products, f.name]).group_by(&:product_id)
            if records[f.name][product.id]
              record_vals[f.name] ||= records[f.name].values.map{|i|i.first.value}
              feature_value = records[f.name][product.id].first.value 
              
              if f.name == "displayDate"
                feature_value = RuleUtility.calculateFactor_displayDate(feature_value)
              
              elsif f.name== "saleEndDate"
                feature_value = RuleUtility.calculateFactor_saleEndDate(feature_value)
              end
            end
          end
          utility << feature_value* (f.value) 
        end
        #Add the static calculated utility
        utilities ||= ContSpec.where(["product_id IN (?) and name = ?", all_products, "utility"]).group_by(&:product_id)
        product_utility = utilities[product.id] ? utilities[product.id].first : ContSpec.new(product_id: product.id, name: "utility")
        product_utility.value = utility.sum
        puts "product_id #{product.id} sku #{product.sku}  utility_sum #{utility.sum}"
        cont_activerecords << product_utility
      end
    
     # Do all record saving at the end for efficiency. :on_duplicate_key_update only works in mysql database
     #ContSpec.import cont_activerecords, :on_duplicate_key_update=>[:product_id, :name, :value, :modified]
     
     cont_activerecords  
  end
  def self.calculateFactor_sale(fVal1, fVal2) 
     fVal1 > fVal2 ? (fVal1-fVal2)/fVal1 : 0
  end
  def self.calculateFactor_displayDate(fVal)
    fVal_str = (fVal +1).to_str
    ret = (Date.today - Date.parse(fVal_str))
    ret
  end
  
  def self.calculateFactor_saleEndDate(fVal)
    ret = (Date.parse(fVal) - Date.today)
    ret = 1/ret if ret
    ret
  end
end

