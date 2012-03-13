# Goes through files in directory, temporarily stores all products bought in same purchase as featured products, 
# then writes the top sold accessories to text spec table under 'top_copurchases'
def find_recommendations (grouping_type, store, products, start_date, end_date, directory)
  before = Time.now
  
  recommended = get_all_accessories(store,products,start_date,end_date,directory)

  # Sorts the accessories into categories, then stores the data in the manner dictated above
  recommended.each_pair do |sku,recommendations|    
    product_id = get_id(sku,:main,store)
    
    # Get presence numbers and top n products for each product_type (sorting part)
    acc_cats = {}
    count = 0
    p "Sorting recommendations for #{sku}"
    recommendations.sort_by{|sku,sales| sales}.reverse.each do |sku|
      acc_sku = sku[0]
      sales = sku[1]
      begin
        cat_id = get_id(acc_sku,:category,store)
        if acc_cats.key?(cat_id)
          acc_cats[cat_id][0] += sales  # Add the number of sales this item has to the product_type total
          acc_cats[cat_id][1].store(acc_sku,sales)
        else
          acc_cats[cat_id] = [sales,{acc_sku=>sales}]
        end
        count += sales # The total sales of all categories (not used for table)
      rescue
        p "Product #{acc_sku} does not exist in the database"  # When database is filled this should rarely be an issue
      end
    end
    
    # Saving part
    case grouping_type
    # Writes data to accessories table (each accessory has sales numbers linked to main product)
    when "table"
      write_to_acc_table(sku,recommendations,acc_cats,store)
    # Writes data to text_specs table -> data is hardcoded -> need to run task again to change it
    when "fixed_categories","numerical"
      # Add top n purchased accessories to string
      text = "Top #{ACCESSORIES_PER_PRODUCT_TYPE}~#{count}~"
      recommendations.sort_by{|sku,sales| sales}.reverse.first(ACCESSORIES_PER_PRODUCT_TYPE).each do |product|
        sku = product[0]
        sales = product[1]
        text += sku.to_s+"~"+sales.to_s+"~"
      end
      case grouping_type
      when "fixed_categories"
        text += preset_acc_select(acc_cats)
      when "numerical"
        text += numerical_acc_select(acc_cats)
      end
      # Write text string to text spec table
      row = TextSpec.find_or_initialize_by_product_id_and_name(product_id,"top_copurchases")
      row.update_attributes(:value => text)
    end
  end

 after = Time.now
 p "Time taken for task: "+(after-before).to_s
end


# Reads files to get all products bought with main products
def get_all_accessories (store,products,start_date,end_date,directory)
  recommended = {}
  purchase = {}
  prev_purchase_id = nil

  for sku in products
    recommended[sku] = Hash.new   # Create empty hash containing only the products wanted : {sku1 => {}, sku2 => {}, ...}
  end

  Dir.foreach(directory) do |file| 
    if file =~ /#{store}_(\d{8})_(\d{8})\.csv$/  # Only process bestbuy/futureshop data files
      file_start_date = Date.strptime($1, '%Y%m%d')
      file_end_date = Date.strptime($2, '%Y%m%d') 

      if start_date <= file_start_date && end_date >= file_end_date #only process files within specified time frame
        csvfile = File.new(directory+"/"+file)

        # Go through file, grouping products into purchases. If a purchase contains a wanted item, add the other purchased items to the item's hash
        File.open(csvfile, 'r') do |f|
          p "Getting sales from #{file}"
          f.each do |line|
            if /\d+,(?<purchase_id>\d+),(?<sku>\d{8}),(?<orders>\d+)/ =~ line
              prev_purchase_id = purchase_id if prev_purchase_id == nil                
              orders = orders.to_i   
              unless purchase_id == prev_purchase_id  # Skip this unless the purchase has ended
                recommended.each do |main_sku,recommend|
                  if purchase.key?(main_sku) # Go through purchase, check for main products wanted
                    purchase.each_pair do |recommend_sku,orders|  
                      unless main_sku == recommend_sku # Transfer orders of all products in purchase other than main products
                        if recommended[main_sku].key?(recommend_sku)
                          recommended[main_sku][recommend_sku] += orders
                        else
                          recommended[main_sku].store(recommend_sku,orders)
                        end
                      end
                    end
                  end
                end
                purchase.clear  # Clear the purchase history
                purchase.store(sku,orders)  # Then fill with most recently read product
                prev_purchase_id = purchase_id  # Then change the previous purchase id to the current purchase id
              else
                purchase.store(sku,orders)
              end
            end
          end
        end
      end
    end
  end
  recommended
end


# Saves the recommended accessories to the accessories table
def write_to_acc_table (sku,recommendations,acc_cats,store)
  p "Saving recommendations for #{sku}"
  sku_id = get_id(sku,:main,store)
  unless sku_id == ""
    # Write the total number of transactions with accessories
    total_sales = 0
    acc_cats.each_pair do |cat,sales|
      total_sales += sales[0]
    end
    accessory = Accessory.find_or_initialize_by_product_id_and_name(sku_id,"accessory_sales_total")
    accessory.update_attribute(:count, total_sales)
    # Write the number of times a product is sold with the desired item
    acc_cats.sort_by{|sku,sales| sales[0]}.reverse.first(NUM_CHOICES).each  do |category|
      cat = category[0]
      cat_sales = category[1][0]
      sku_hash = category[1][1]
      unless cat == "" # This means the product(s) has/have no category in db (I think)
        accessory = Accessory.find_or_initialize_by_product_id_and_name_and_value_and_acc_type(sku_id,"accessory_type",cat,cat)
        accessory.update_attribute(:count, cat_sales)
        sku_hash.each_pair do |acc_sku, sales|
          acc_id = get_id(acc_sku,:accessory,store)
          unless acc_id == ""
            accessory = Accessory.find_or_initialize_by_product_id_and_name_and_value_and_acc_type(sku_id,"accessory_id",acc_id,cat)
            accessory.update_attribute(:count, sales)
          else
            p "Accessory #{acc_sku} does not have the information necessary"
          end
        end
      end
    end
    # Ensure top 'NUM_CHOICES' accessories are in db table
    recommendations.sort_by{|sku,sales| sales}.reverse.first(NUM_CHOICES).each do |acc|
      acc_sku = acc[0]
      sales = acc[1]
      acc_id = get_id(acc_sku,:accessory,store)
      unless acc_id == ""
        accessory = Accessory.find_or_initialize_by_product_id_and_name_and_value(sku_id,"accessory_id",acc_id)
        accessory.update_attribute(:count, sales)
      else
        p "Accessory #{acc_sku} does not have the information necessary"
      end
    end
  else
    p "Product #{sku} is unidentifiable in database/will not successfully save accessories"
  end
end


# Check in case there are duplicates in the db
def get_id (sku,type,store)
  id = ""
  case type
  when :main
    sku_ids = Product.select(:id).where(:sku => sku)
    sku_ids.each do |product|
      unless 0 == ContSpec.joins("INNER JOIN `cat_specs` ON `cont_specs`.product_id = `cat_specs`.product_id").where("`cont_specs`.product_id = ? AND `cat_specs`.name = ? AND `cat_specs`.value REGEXP ?",product.id,'product_type',store).count("*")
        id = product.id
      end
    end
  when :accessory
    acc_ids = Product.select(:id).where(:sku => sku)
    acc_ids.each do |accessory|
      unless 0 == CatSpec.where("`cat_specs`.product_id = ? AND `cat_specs`.name = ? AND `cat_specs`.value REGEXP ?",accessory.id,'product_type',store).count("*")
        id = accessory.id
      end
    end
  when :category
    # Eventually add ability to find most suitable product type (when one product is in multiple categories)
    CatSpec.select(:value).joins("INNER JOIN `products` ON `cat_specs`.product_id = `products`.id").where(products: {sku:sku}, cat_specs: {name:"product_type"}).each do |cat|
      if cat.value =~ /^#{store}/
        id = cat.value
      end
    end
  end
  id
end


# Only add the categories listed/specified above
def preset_acc_select (acc_cats)
  cat_sales = {}
  # Only add the categories listed/specified above
  ACCESSORY_CATEGORIES.each do |cat_id|
    Session.new(cat_id)
    cat_ids = Session.product_type_leaves 
    all_prods = {}
    total_sales = 0
    cat_ids.each do |category|
      begin
        all_prods.merge!(acc_cats[category][1]){|key| raise "Error: sku #{key} is in two categories"}
        total_sales += acc_cats[category][0]
      rescue
        p "Product type #{category} does not have any sales"
      end
    end
    Translation.select(:value).where(:key=>cat_id+".name").first.value =~ /--- (.+)/
    trans = $1
    temp_text = "%"+trans+"~"+total_sales.to_s+"~"
    all_prods.sort_by{|key,value| value}.reverse.first(ACCESSORIES_PER_PRODUCT_TYPE).each do |product|
      temp_text += product[0]+"~"+product[1].to_s+"~"
    end
    cat_sales.store(total_sales,temp_text)
  end
  text = ""
  cat_sales.sort.reverse.each do |sales|
    text += sales[1]
  end
  text
end


# Add top n product_types (in terms of total purchases) to string
def numerical_acc_select (acc_cats)
  text = ""
  acc_cats.sort_by{|cat,sales| sales[0]}.reverse.first(ACCESSORY_TYPES_PER_BESTSELLING).each do |product_type|
    unless product_type[0] == "" # Category in which unplaceable items are put (no other known category accepts them)
      cat_sales = product_type[1][0]
      acc_hash = product_type[1][1]
      Translation.select(:value).where(:key=>product_type[0]+".name").first.value =~ /--- (.+)/
      trans = $1
      text += "%"+trans+"~"+cat_sales.to_s+"~"
      acc_hash.sort_by{|sku,sales| sales}.reverse.first(ACCESSORIES_PER_PRODUCT_TYPE).each do |product|
        text += product[0]+"~"+product[1].to_s+"~"
      end
    end
  end
  text
end