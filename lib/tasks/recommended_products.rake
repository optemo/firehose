# Returns array containing top co-purchased products (for recommended products/accessories)
task :recommended_products, [:start_date, :end_date, :directory]=> :environment do |t, args|
  #--- Choose product type and grouping type ---#
  product_types=["F22553"]
  grouping_type = "table" # Saves data to accessory table
#  grouping_type = "fixed_categories" # User determines accessory categories to be filled below as constant
#  grouping_type = "numerical" # Chooses the top categories in terms of numbers of products sold
  
  args.with_defaults(:start_date=>"20110801", :end_date=>"20111231", :directory=>"/Users/marc/Documents/Best_Buy_Data/second_set")
  start_date = Date.strptime(args.start_date, '%Y%m%d')
  end_date = Date.strptime(args.end_date, '%Y%m%d')
  if product_types.first =~ /^B/
    store = 'B'
  elsif product_types.first =~ /^F/
    store = 'F'
  else
    raise "Invalid product type and/or store"
  end
  products = []
  AccessoriesController.new.get_products(product_types).each do |product|
    product[1].each do |sku|
      products.push(sku.sku)  # Get products from Featured Controller
    end
  end
  debugger
  products.uniq!  # Remove bundle duplicates
  p "Best Selling Products: #{products}"
  find_recommendations(grouping_type, store, products, start_date, end_date, args.directory)
end

ACCESSORIES_PER_PRODUCT_TYPE = 10
ACCESSORY_TYPES_PER_BESTSELLING = 5
ACCESSORY_CATEGORIES = ["B20001a","B29578","B21202","B20330"] # Laptops  ["B20206","B21245","B21310","B21976"] # TVS

# Goes through files in directory, temporarily stores all products bought in same purchase as featured products, 
# then writes the top sold accessories to text spec table under 'top_copurchases'
def find_recommendations (grouping_type, store, products, start_date, end_date, directory)
  recommended = {}
  purchase = {}
  prev_purchase_id = nil
  
  for sku in products
    recommended[sku] = Hash.new   # Create empty hash containing only the products wanted : {sku1 => {}, sku2 => {}, ...}
  end
  
  before = Time.now
  Dir.foreach(directory) do |file| 
    if file =~ /#{store}_(\d{8})_(\d{8})\.csv$/  # Only process bestbuy/futureshop data files
      file_start_date = Date.strptime($1, '%Y%m%d')
      file_end_date = Date.strptime($2, '%Y%m%d') 
      
      if start_date <= file_start_date && end_date >= file_end_date #only process files within specified time frame
        csvfile = File.new(directory+"/"+file)
        
        # Go through file, grouping products into purchases. If a purchase contains a wanted item, add the other purchased items to the item's hash
        File.open(csvfile, 'r') do |f|
          p "Getting sales from #{csvfile}"
          f.each do |line|
            if line =~ /\d+,(\d+),(\d{8}),(\d+)/
              purchase_id = $1
              prev_purchase_id = purchase_id if prev_purchase_id == nil
              sku = $2                 
              orders = $3.to_i   
              unless purchase_id == prev_purchase_id  # Skip this unless the purchase has ended
                recommended.each do |sku,recommend|
                  if purchase.key?(sku) # Go through purchase, check for products wanted
                    purchase.each_pair do |recommend_sku,orders|  # Transfer orders of all products in purchase other than those wanted above
                      unless sku == recommend_sku
                        if recommended[sku].key?(recommend_sku)
                          recommended[sku][recommend_sku][0] = recommended[sku][recommend_sku][0] + orders
                          recommended[sku][recommend_sku][1] += 1
                        else
                          recommended[sku].store(recommend_sku,[orders,1])
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
  
  # Sorts the accessories into categories, then stores the data in the manner dictated above
  recommended.each_pair do |sku,recommendations|      
    product_id = Product.select(:id).where("sku=?",sku.to_s).first.id # This line may be problematic if products have more than one product_id (bundles)
  
    # Get presence numbers and top n products for each product_type
    acc_cats = {}
    count = 0
    p "Sorting recommendations for #{sku}"
    recommendations.sort_by{|a,b| b[1]}.reverse.each do |sku|
      begin
        cat_id = ""
        CatSpec.select(:value).joins("INNER JOIN `products` ON `cat_specs`.product_id = `products`.id").where(products: {sku:sku[0]}, cat_specs: {name:"product_type"}).each do |cat|
          if cat.value =~ /^#{store}/
            cat_id = cat.value
          end
        end
        if acc_cats.key?(cat_id)
          acc_cats[cat_id][0] += sku[1][1]  # Add the number of sales this item has to the product_type total
          
          #check if works properly for all options like this (commented)
          #if acc_cats[cat_id][1].length < ACCESSORIES_PER_PRODUCT_TYPE  # Limit the number of entries one product_type can hold
            acc_cats[cat_id][1].store(sku[0],sku[1][1])
          #end
        else
          acc_cats[cat_id] = [sku[1][1],{sku[0]=>sku[1][1]}]
        end
        count += sku[1][1]
      rescue
        p "Product #{sku[0]} does not exist in the database"  # When database is filled this should rarely be an issue
      end
    end

    case grouping_type
    # Writes data to accessories table (each accessory has sales numbers linked to main product)
    when "table"
      # Test this function when duplicates problem solved
      p "Saving recommendations for #{sku}"
      sku_id = ""
      sku_ids = Product.select(:id).where(:sku => sku)
      # Check in case there are duplicates in the db
      sku_ids.each do |product|
        unless 0 == ContSpec.joins("INNER JOIN `cat_specs` ON `cont_specs`.product_id = `cat_specs`.product_id").where("`cont_specs`.product_id = ? AND `cat_specs`.name = ? AND `cat_specs`.value REGEXP ?",product.id,'product_type',store).count("*")
          sku_id = product.id
        end
      end
      unless sku_id == ""
        # Write the number of times a product is sold with the desired item
        acc_cats.each_pair  do |cat, data|
          unless cat == "" # This means the product no longer exists on the site
            accessory = Accessory.find_or_initialize_by_product_id_and_name_and_value_and_acc_type(sku_id,"accessory_type",cat,cat)
            accessory.update_attribute(:count, data[0])
            accessory.save
            data[1].each_pair do |acc_sku, sales|
              acc_id = ""
              acc_ids = Product.select(:id).where(:sku => acc_sku)
              # Check in case there are duplicates in the db
              acc_ids.each do |accessory|
                unless 0 == CatSpec.where("`cat_specs`.product_id = ? AND `cat_specs`.name = ? AND `cat_specs`.value REGEXP ?",accessory.id,'product_type',store).count("*")
                  acc_id = accessory.id
                end
              end
              unless acc_id == ""
                accessory = Accessory.find_or_initialize_by_product_id_and_name_and_value_and_acc_type(sku_id,"accessory_id",acc_id,cat)
                #if accessory.count == nil
                  accessory.count = sales
                #else
                #  accessory.count += sales
                #end
                accessory.save
              end
            end
          end
        end
      end
    
    # Writes data to text_specs table -> data is hardcoded -> need to run task again to change it
    when "fixed_categories","numerical"
      # Add top n purchased accessories to string
      text = "Top #{ACCESSORIES_PER_PRODUCT_TYPE}~#{count}~"
      products = recommendations.sort_by{|a,b| b[1]}.reverse.first(ACCESSORIES_PER_PRODUCT_TYPE)
      products.each do |index|
        text += index[0].to_s+"~"+index[1][1].to_s+"~"
      end
      
      case grouping_type
      when "fixed_categories"
        # Only add the categories listed/sepecified above
        cat_sales = {}
        ACCESSORY_CATEGORIES.each do |cat_id|
          Session.new(cat_id)          # is it possible to create a session with multiple ids to avoid this?
          if Session.product_type_leaves.empty?
            cat_ids = [cat_id]
          else
            cat_ids = Session.product_type_leaves 
          end
          all_prods = {}
          transactions = 0
          cat_ids.each do |category|
            begin
              all_prods.merge!(acc_cats[category][1]){|key| raise "Error: sku #{key} is in two categories"}
              transactions += acc_cats[category][0]
            rescue
              p "Product type #{category} does not have any sales"
            end
          end
          Translation.select(:value).where(:key=>cat_id+".name").first.value =~ /--- (.+)/
          trans = $1
          temp_text = ""
          temp_text += "%"+trans+"~"+transactions.to_s+"~"
          all_prods.sort_by{|key,value| value}.reverse.first(ACCESSORIES_PER_PRODUCT_TYPE).each do |product|
            temp_text += product[0]+"~"+product[1].to_s+"~"
          end
          cat_sales.store(transactions,temp_text)
        end
        cat_sales.sort.reverse.each do |sales|
          text += sales[1]
        end
      when "numerical"
        # Add top n product_types (in terms of total purchases) to string
        acc_cats.sort_by{|a,b| b[0]}.reverse.first(ACCESSORY_TYPES_PER_BESTSELLING).each do |product_type|
          Translation.select(:value).where(:key=>product_type[0]+".name").first.value =~ /--- (.+)/
          trans = $1
          text += "%"+trans+"~"+product_type[1][0].to_s+"~"
          product_type[1][1].sort_by{|key,value| value}.reverse.first(ACCESSORIES_PER_PRODUCT_TYPE).each do |product|
            text += product[0]+"~"+product[1].to_s+"~"
          end
        end
      end
      # Write text string to text spec table
      row = TextSpec.find_or_initialize_by_product_id_and_name(product_id,"top_copurchases")
      row.update_attributes(:value => text)
    end
  end

 after = Time.now
 p "Time taken for task: "+(after-before).to_s

end