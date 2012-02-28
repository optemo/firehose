#                               Product Type ID (can be parent or leaf)
#                                                   |
#example call: bundle exec rake find_bestselling["B29361"","20110801","20110831","/Users/marc/Documents/Best_Buy_Data/second_set"]
task :update_store_sales, [:product_type, :start_date, :end_date, :directory] => :environment do |t, args|
  args.with_defaults(:start_date=>"20110801", :end_date=>"20111231", :directory=>"/Users/marc/Documents/Best_Buy_Data/second_set")
  start_date = Date.strptime(args.start_date, '%Y%m%d')
  end_date = Date.strptime(args.end_date, '%Y%m%d')
  # Get all leaf nodes within product_type specified
  Session.new(args.product_type)
  if Session.product_type_leaves.empty?
    product_types = args.product_type
  else
    product_types = Session.product_type_leaves 
  end
  debugger
  update_store_sales(product_types, start_date, end_date, args.directory)
end

# Finds all instock products for each day of a given month, looks up the daily sales for these products in the 
# files sent by bestbuy (.csv), stores the daily sales in the all_daily_spec table (firehose_development)
def update_store_sales (product_types, start_date, end_date, directory)
  require 'date'
  ids = []
  prods = {}
  start_time = Time.now
  
  skus = CatSpec.select("sku,product_id").joins("INNER JOIN `products` ON `cat_specs`.product_id = `products`.id").where(cat_specs: {name: :product_type, value: product_types})
  
  skus.each do |product|
    prods[product.sku] = [product.product_id, 0]
  end
  debugger
  Dir.foreach(directory) do |file|
    #only process bestbuy data files
    if file =~ /B_\d{8}_\d{8}\.csv/
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
            m = /^0,\d+,(\d+),(\d+),\d+\.?\d*,(\d+).*/.match(line)
            #only continue if line has format of regex
            if m != nil
              sku = $1
              sales = $2.to_i
              if sku == "M2192735"
                debugger
              end
              if prods.key?(sku)
                debugger
                prods[sku][1] += sales
              end
            end
          end
        end
        after = Time.now
        p "Time taken (s) for sales from #{month}: "+(after-before).to_s
      end
    end
  end
  
  # Create or update a row in ContSpec for sum of instore sales for a product
  prods.each do |product|
    p_id = product[1][0]
    sales = product[1][1]
    row = ContSpec.find_or_create_by_product_id_and_name(p_id,"sum_store_sales")
    row.update_attributes(:value => sales)
  end
  
  end_time = Time.now
  p "Time taken (s) for all files: "+(end_time-start_time).to_s
end