# When saving individual accessories to table:
NUM_CHOICES = 15 # Default number of accessory categories per product and accessories per accessory category
# When saving all accessories wanted as one text spec:
ACCESSORIES_PER_PRODUCT_TYPE = 10
ACCESSORY_TYPES_PER_BESTSELLING = 5
ACCESSORY_CATEGORIES = ["F25814","F25815","F25816"] # FS DSLR's

# Returns array containing top co-purchased products (for recommended products/accessories)
task :recommended_products, [:product_type, :start_date, :end_date, :directory]=> :environment do |t, args|
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
  
   # Just to check products are correct
  products.uniq!  # Remove bundle duplicates
  p "Best Selling Products: #{products}"
  find_recommendations(grouping_type, store, products, start_date, end_date, args.directory)
end