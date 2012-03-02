# Returns array containing top co-purchased products (for recommended products/accessories)
task :recommended_products, [:start_date, :end_date, :directory]=> :environment do |t, args|
  args.with_defaults(:start_date=>"20110801", :end_date=>"20111231", :directory=>"/Users/marc/Documents/Best_Buy_Data/second_set")
  start_date = Date.strptime(args.start_date, '%Y%m%d')
  end_date = Date.strptime(args.end_date, '%Y%m%d')
  products = []
  FeaturedController.new.index.each do |product|
    product[1].each do |sku|
      products.push(sku.sku)  # Get products from Featured Controller
    end
  end
  debugger
  products.uniq!  # Remove bundle duplicates
  p "Best Selling Products: #{products}"
  find_recommendations(products, start_date, end_date, args.directory)
end

ACCESSORIES_PER_PRODUCT_TYPE = 10
ACCESSORY_TYPES_PER_BESTSELLING = 5
ACCESSORY_CATEGORIES = ["B20001a","B29578","B21202","B20330"] # Laptops  ["B20206","B21245","B21310","B21976"] # TVS

# Note: function can both find only the accessory categories selected above, or choose the top n (Accessory_types_per_bestselling) categories
# Must (un)comment appropriate block below to choose

# Goes through files in directory, temporarily stores all products bought in same purchase as featured products, 
# then writes the top sold accessories to text spec table under 'top_copurchases'
def find_recommendations (products, start_date, end_date, directory)
  recommended = {}
  purchase = {}
  prev_purchase_id = nil
  
  for sku in products
    recommended[sku] = Hash.new   # Create empty hash containing only the products wanted
  end
  
  before = Time.now
  
  Dir.foreach(directory) do |file| 
    if file =~ /B_(\d{8})_(\d{8})\.csv$/  # Only process bestbuy data files
      file_start_date = Date.strptime($1, '%Y%m%d')
      file_end_date = Date.strptime($2, '%Y%m%d') 
      
      if start_date <= file_start_date && end_date >= file_end_date #only process files within specified time frame
        csvfile = File.new(directory+"/"+file)
        
        # Go through file, grouping products into purchases. If a purchase contains a wanted item, add the other purchased items to the item's hash
        File.open(csvfile, 'r') do |f|
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
  
  # Print top 10 recommended products
  # For testing -> useless afterwards -> remove
  recommended.each_pair do |sku,recommendations|  
    p "Product #{sku} accessories (sorted by presence)"+recommendations.sort_by{|a,b| b[1]}.reverse.first(10).to_s
  end
  
  # Creates/Updates a database entry for the product, writing the 10 most popular accessories and the number of purchases in which they are present
  recommended.each_pair do |sku,recommendations|      
    product_id = Product.select(:id).where("sku=?",sku.to_s).first.id # This line may be problematic if products have more than one product_id (bundles)
    
    # Get presence numbers and top n products for each product_type
    acc_cats = {}
    count = 0
    recommendations.sort_by{|a,b| b[1]}.reverse.each do |sku|
      begin
        cat_id = CatSpec.select(:value).joins("INNER JOIN `products` ON `cat_specs`.product_id = `products`.id").where(products: {sku:sku[0]}, cat_specs: {name:"product_type"}).first.value
        if acc_cats.key?(cat_id)
          acc_cats[cat_id][0] += sku[1][1]  # Add the number of sales this item has to the product_type total
          if acc_cats[cat_id][1].length < ACCESSORIES_PER_PRODUCT_TYPE  # Limit the number of entries one product_type can hold
            acc_cats[cat_id][1].store(sku[0],sku[1][1])
          end
        else
          acc_cats[cat_id] = [sku[1][1],{sku[0]=>sku[1][1]}]
        end
        count += sku[1][1]
      rescue
        p "Product #{sku[0]} does not exist in the database"  # When database is filled this should rarely be an issue
      end
    end
    
    # Add top n purchased accessories to string
    text = "Top #{ACCESSORIES_PER_PRODUCT_TYPE}~#{count}~"
    products = recommendations.sort_by{|a,b| b[1]}.reverse.first(ACCESSORIES_PER_PRODUCT_TYPE)
    products.each do |index|
      text += index[0].to_s+"~"+index[1][1].to_s+"~"
    end
    
 #   # Only add the categories listed/sepecified above
 #   cat_sales = {}
 #   ACCESSORY_CATEGORIES.each do |cat_id|
 #     Session.new(cat_id)          # is it possible to create a session with multiple ids to avoid this?
 #     if Session.product_type_leaves.empty?
 #       cat_ids = [cat_id]
 #     else
 #       cat_ids = Session.product_type_leaves 
 #     end
 #     all_prods = {}
 #     transactions = 0
 #     cat_ids.each do |category|
 #       begin
 #         all_prods.merge!(acc_cats[category][1]){|key| raise "Error: sku #{key} is in two categories"}
 #         transactions += acc_cats[category][0]
 #       rescue
 #         p "Product type #{category} does not have any sales"
 #       end
 #     end
 #     Translation.select(:value).where(:key=>cat_id+".name").first.value =~ /--- (.+)/
 #     trans = $1
 #     temp_text = ""
 #     temp_text += "%"+trans+"~"+transactions.to_s+"~"
 #     all_prods.sort_by{|key,value| value}.reverse.first(ACCESSORIES_PER_PRODUCT_TYPE).each do |product|
 #       temp_text += product[0]+"~"+product[1].to_s+"~"
 #     end
 #     cat_sales.store(transactions,temp_text)
 #   end
 #   cat_sales.sort.reverse.each do |sales|
 #     text += sales[1]
 #   end
    
    # Add top n product_types (in terms of total purchases) to string
    acc_cats.sort_by{|a,b| b[0]}.reverse.first(ACCESSORY_TYPES_PER_BESTSELLING).each do |product_type|
      Translation.select(:value).where(:key=>product_type[0]+".name").first.value =~ /--- (.+)/
      trans = $1
      text += "%"+trans+"~"+product_type[1][0].to_s+"~"
      product_type[1][1].sort_by{|key,value| value}.reverse.first(ACCESSORIES_PER_PRODUCT_TYPE).each do |product|
        text += product[0]+"~"+product[1].to_s+"~"
      end
    end
    
    # Write text string to text spec table
    row = TextSpec.find_or_initialize_by_product_id_and_name(product_id,"top_copurchases")
    row.update_attributes(:value => text)
  end

 after = Time.now
 p "Time taken for task: "+(after-before).to_s

end