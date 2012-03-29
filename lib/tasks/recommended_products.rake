# When saving individual accessories to table:
NUM_CHOICES = 15 # Default number of accessory categories per product and accessories per accessory category
# When saving all accessories wanted as one text spec:
ACCESSORIES_PER_PRODUCT_TYPE = 10
ACCESSORY_TYPES_PER_BESTSELLING = 5
ACCESSORY_CATEGORIES = ["F25814","F25815","F25816"] # FS DSLR's

# Saves top accessories for each best seller
task :recommended_products, [:product_type, :start_date, :end_date, :directory]=> :environment do |t, args|
  unless Rails.env == "accessories"
    raise "Please use the 'accessories' environment and table"
  end
  require 'accessory_recommendations'

  product_type = args.product_type
  #--- Choose grouping type ---#
  grouping_type = "table" # Saves data to accessory table
#  grouping_type = "fixed_categories" # User determines accessory categories to be filled (above as constant)
#  grouping_type = "numerical" # Chooses the top categories in terms of numbers of products sold
  
  # Eventually take this out after testing
  args.with_defaults(:start_date=>"20110801", :end_date=>"20111231", :directory=>"/Users/marc/Documents/Best_Buy_Data/second_set")
  
  start_date = Date.strptime(args.start_date, '%Y%m%d')
  end_date = Date.strptime(args.end_date, '%Y%m%d')
  
  if product_type =~ /^[BF]/
    store = product_type[0]
  else
    raise "Invalid product type and/or store" 
  end
  
  products = []
  AccessoriesController.new.get_products([product_type]).each do |product|
    product[1].each do |sku|
      products.push(sku.sku)  # Get products from Accessories Controller
    end
  end
  
  products.uniq!  # Remove bundle duplicates
  p "Best Selling Products: #{products}"
  find_recommendations(grouping_type, store, products, start_date, end_date, args.directory)
end

#MAYBE JUST REMOVE
## NOT DONE YET
#    # Runs all necessary updates to make sure accessories are up to date (may take a very long time)
#    # Specify dates for limits on sales as well as where to find the sales
#    task :update_accessories, [:start_date, :end_date, :directory] => :environment do |t,args|
#      unless Rails.env == "accessories"
#        raise "Please use the 'accessories' environment and table"
#      end
#      args.with_defaults(:start_date=>"20110801", :end_date=>"20111231", :directory=>"/Users/marc/Documents/Best_Buy_Data/second_set")
#    #                          laptop   tablet    TV   fridge  camera   DSLR    laptop    tablet    TV      camera    DSLR
#    #  cats_with_accessories = ['F1002','F29958','Ftvs','F1953','F1127','F23773','B20352','B30297','B21344','B20218','B29157']
#      cats_with_accessories = ['B20218']
#      broad_categories = []
#      cats_with_accessories.each do |category|
#        Session.new(category)
#        broad_cat = Session.product_type_path.second
#        unless broad_categories.include?(broad_cat)
#          broad_categories.push(broad_cat)
#        end
#      end
#      debugger
#    #  broad_categories.each do |broad_cat|
#    #    # Get all products within category sold by retailer
#    #    %x[rake update product_type=#{broad_cat}]
#    #  end
#      cats_with_accessories.each do |category|
#        # Get the bestseller sales numbers of products in the category
#        %x[rake update_store_sales[#{category}, false, args.start_date, args.end_date, args.directory]]
#        # Get the accessories for each best seller
#        %x[rake recommended_products[#{category}, args.start_date, args.end_date, args.directory]]
#      end  
#    end
