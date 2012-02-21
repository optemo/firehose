# Returns array containing top co-purchased products (for recommended products/accessories)
task :recommended_products, [:start_date, :end_date, :directory]=> :environment do |t, args|
  products = ["10164172","10176955"]
#  products = []
#  FeaturedController.new.index.each do |product|
#    products.push(product.sku)  # Get products from Featured Controller
#  end
#  products.uniq!  # Remove bundle duplicates
  start_date = Date.strptime(args.start_date, '%Y%m%d')
  end_date = Date.strptime(args.end_date, '%Y%m%d')
  find_recommendations(products, start_date, end_date, args.directory)
end

# Goes through files in directory, temporarily stores all products bought in same purchase as featured products
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
  
  recommended.each_pair do |sku,recommendations|  # Print top 10 recommended products
   p "Product #{sku} accessories (sorted by presence)"+recommendations.sort_by{|a,b| b[1]}.reverse.first(10).to_s
   p "Product #{sku} accessories (sorted by orders)"+recommendations.sort_by{|a,b| b[0]}.reverse.first(10).to_s
  end
  
  # Creates/Updates a database entry for the product, writing the 10 most popular accessories and the number of purchases in which they are present
  recommended.each_pair do |sku,recommendations|      
    product_id = Product.select(:id).where("sku=?",sku.to_s).first.id # This line may be problematic if products have more than one product_id (bundles)
    text = ""
    products = recommendations.sort_by{|a,b| b[1]}.reverse.first(10)
    products.each do |index|
      text += (index[0].to_s+"-"+index[1][1].to_s+"-")
    end
    text.chop!
    row = TextSpec.find_or_initialize_by_product_id_and_name(product_id,"top_copurchases")
  end

 after = Time.now
 p "Time taken for task: "+(after-before).to_s

end  