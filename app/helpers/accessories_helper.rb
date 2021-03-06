module AccessoriesHelper
  
  # Returns accessories for a given product
  def get_accessories (product)
    acc = {}
    total_purchases = product.total_acc_sales
    acc["Top 5"] = [total_purchases,Accessory.select("value,count").where(:product_id => product.id, :name => "accessory_id").order("count DESC").limit(@accessories_per_product_type)]
    leaves_included = []
    Accessory.select("value,count").where(:name => "accessory_type", :product_id => product.id).order("count DESC").limit(@accessory_types_per_bestselling).each do |cat|
      accessories = Accessory.select("value,count").where(:acc_type => cat.value, :name => "accessory_id", :product_id => product.id).order("count DESC").limit(@accessories_per_product_type)
      unless cat.value == "B0000" # Category for products with unknown category 
        # Only add products from leaves that are not already added
        unless leaves_included.include?(cat.value) 
          # Go to the parent node if this check passes, otherwise continue with leaf node
          if accessories.length < @accessories_per_product_type || accessories.last.count < @selling_threshold
            parent = ProductCategory.get_parent(cat.value)
            leaves = ProductCategory.get_leaves(parent)
            leaves.each do |leaf|
              leaves_included.push(leaf)
            end
            parent_purchases = Accessory.where(:product_id => product.id, :name => 'accessory_type', :value => leaves).sum("count")
            acc[t("#{parent.first}.name")] = [parent_purchases,Accessory.select("value,count").where(:acc_type => leaves, :name => "accessory_id", :product_id => product.id).order("count DESC").limit(@accessories_per_product_type)]
          else
            acc[t(cat.value+".name")] = [cat.count,accessories]
            leaves_included.push(cat.value)
          end
        end
      end
    end

    acc["Top 5: Limited"] = [total_purchases, get_top_limited(product)]
    acc
  end
  
  # Returns accessories in a given category for a given product
  def get_select_accessories (product, accessory_type, count)
    acc = {}
    case accessory_type
    when "Top #{@accessories_per_product_type}"
      acc["Top #{@accessories_per_product_type}"] = [count,Accessory.select("value,count").where(:product_id => product.id, :name => "accessory_id").order("count DESC").limit(@accessories_per_product_type)]
    when "Top #{@accessories_per_product_type}: Limited"
      acc["Top #{@accessories_per_product_type}: Limited"] = [count,get_top_limited(product)]
    else
      acc[t("#{accessory_type}.name")] = [count,Accessory.select("value,count").where(:acc_type => accessory_type, :name => "accessory_id", :product_id => product.id).order("count DESC").limit(@accessories_per_product_type)]
    end
    acc
  end
  
  # Gets the top n accessories, limiting the number of times products from a category show up
  def get_top_limited (product)
    product_accessories = []
    backup_accessories = []
    cats_included = {}
    sales_needed = product.total_acc_sales*@top_n_limit_percent
    accessories = Accessory.where(:product_id => product.id, :name => "accessory_id").order("count DESC").limit(@accessories_per_product_type*5)
    accessories.each do |accessory|
      unless cats_included.key?(accessory.acc_type)
        cats_included[accessory.acc_type] = 0
      end
    end
    
    accessories.each do |accessory|
      if product_accessories.length < @accessories_per_product_type
        if accessory.count >= sales_needed 
          if cats_included[accessory.acc_type] < @top_n_limit_number
            product_accessories.push(accessory)
            cats_included[accessory.acc_type] += 1
          elsif backup_accessories.length < @accessories_per_product_type
            backup_accessories.push(accessory)
          end
        end
      end
    end
    # If there aren't N products in the top-N, boost the limit number to try to fill it in more
    if product_accessories.length < @accessories_per_product_type
      backup_accessories.each do |accessory|
        if product_accessories.length < @accessories_per_product_type
          if accessory.count >= sales_needed 
            if cats_included[accessory.acc_type] < @top_n_limit_number+1
              product_accessories.push(accessory)
              cats_included[accessory.acc_type] += 1
            end
          end
        end
      end
    end
    product_accessories.sort_by{|acc| acc.count}.reverse
  end
  
  def get_cats_and_counts (product)
    types = Accessory.select("value,count").where(:name => "accessory_type", :product_id => product.id).order("count DESC").limit(@accessory_types_per_bestselling*2)
  end

end
