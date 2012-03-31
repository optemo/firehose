NUM_PRODUCTS = 20

#                               Product Type ID (can be parent or leaf)
#                                                   |
#example call: bundle exec rake update_store_sales["B29361",false,"20110801","20110831","/Users/marc/Documents/Best_Buy_Data/second_set"]

# If give :do_all_products = true , will save sales for all products under store_sales. Otherwise only saves top NUM_PRODUCTS sales under bestseller_store_sales
task :update_store_sales, [:product_type, :do_all_products, :start_date, :end_date, :directory] => :environment do |t, args|
  unless Rails.env == "accessories"
    raise "Please use the 'accessories' environment and table"
  end
  # Change these default dates to get the longest stretch allowed by the sales files
  args.with_defaults(:do_all_products=>"false", :start_date=>"20110801", :end_date=>"20111231", :directory=>"/Users/marc/Documents/Best_Buy_Data/second_set")
  start_date = Date.strptime(args.start_date, '%Y%m%d')
  end_date = Date.strptime(args.end_date, '%Y%m%d')
  do_all_products = (args.do_all_products == "true") ? true : false
  if args.product_type =~ /^[Bb]/
    store = 'B'
  elsif args.product_type =~ /^[Ff]/
    store = 'F'
  else
    raise "Unrecognized Product Type and Store"
  end
  # Get all leaf nodes within product_type specified
  if args.product_type == 'B30297' # BB tablets includes its accessories within this category
    update_store_sales(["B29059","B20356","B31040","B31042","B32300"], do_all_products, store, start_date, end_date, args.directory)
  else
    Session.new(args.product_type)
    update_store_sales(Session.product_type_leaves, do_all_products, store, start_date, end_date, args.directory)
  end
end

# Finds all instock products for each day of a given month, looks up the daily sales for these products in the 
# files sent by bestbuy (.csv), stores the daily sales in the all_daily_spec table (firehose_development)
def update_store_sales (product_types, do_all_products, store, start_date, end_date, directory)
  require 'date'
  ids = []
  prods = {}
  start_time = Time.now
  
  skus = CatSpec.select("sku,product_id").joins("INNER JOIN `products` ON `cat_specs`.product_id = `products`.id").where(cat_specs: {name: :product_type, value: product_types})
  
  skus.each do |product|
    prods[product.sku] = [product.product_id, 0]
  end

  Dir.foreach(directory) do |file|
    #only process bestbuy/futureshop data files
    if file =~ /#{store}_\d{8}_\d{8}\.csv/
      
      /(\d{8})_(\d{8})\.csv$/.match(file)
      file_start_date = Date.strptime($1, '%Y%m%d')
      file_end_date = Date.strptime($2, '%Y%m%d') 
      #only process files within specified time frame
      if start_date <= file_start_date && end_date >= file_end_date
        before = Time.now
        csvfile = File.new(directory+"/"+file)
        month = file_start_date..file_end_date
       
      # GO THROUGH THE FILE, ONLY ADDING PRODUCTS IN PRODS HASH MADE ABOVE
        File.open(csvfile, 'r') do |f|
          f.each do |line|
            m = /^0,\d+,(\d+),([-\d]+),\d+\.?\d*,(\d+).*/.match(line)
            #only continue if line has format of regex
            if m != nil
              sku = $1
              sales = $2.to_i
              if prods.key?(sku)
                prods[sku][1] += sales
              end
            else
              #p "Could no match line: #{line}"
            end
          end
        end
        after = Time.now
        p "Time taken (s) for sales from #{month}: "+(after-before).to_s
      end
    end
  end
  
  # May eventually need to add function to erase old sales/sales of items that no longer exist or are not in category
  # Create or update a row in ContSpec for sum of instore sales for a product
  if do_all_products
    prods.sort_by{|sku,value| value[1]}.reverse.each do |product|
      p_id = product[1][0]
      sales = product[1][1]
      row = ContSpec.find_or_create_by_product_id_and_name(p_id,"store_sales")
      row.update_attributes(:value => sales)
    end
  else
    prods.sort_by{|sku,value| value[1]}.reverse.first(NUM_PRODUCTS).each do |product|
      p_id = product[1][0]
      sales = product[1][1]
      row = ContSpec.find_or_create_by_product_id_and_name(p_id,"bestseller_store_sales")
      row.update_attributes(:value => sales)
    end
  end
  
  end_time = Time.now
  p "Time taken (s) for all files: "+(end_time-start_time).to_s
end
