NUM_PRODUCTS = 20
#                               Product Type ID (can be parent or leaf)
#                                                   |
#example call: bundle exec rake find_bestselling["B29361"","20110801","20110831","/Users/marc/Documents/Best_Buy_Data/second_set"]
task :update_store_sales, [:product_type, :start_date, :end_date, :directory] => :environment do |t, args|
  args.with_defaults(:start_date=>"20110801", :end_date=>"20111231", :directory=>"/Users/marc/Documents/Best_Buy_Data/second_set")
  start_date = Date.strptime(args.start_date, '%Y%m%d')
  end_date = Date.strptime(args.end_date, '%Y%m%d')
  if args.product_type =~ /^[Bb]/
    store = 'B'
  elsif args.product_type =~ /^[Ff]/
    store = 'F'
  else
    raise "Unrecognized Product Type and Store"
  end
  # Get all leaf nodes within product_type specified
  Session.new(args.product_type)
  debugger
  update_store_sales(Session.product_type_leaves, store, start_date, end_date, args.directory)
end

# Finds all instock products for each day of a given month, looks up the daily sales for these products in the 
# files sent by bestbuy (.csv), stores the daily sales in the all_daily_spec table (firehose_development)
def update_store_sales (product_types, store, start_date, end_date, directory)
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
  prods.sort_by{|sku,value| value[1]}.reverse.first(NUM_PRODUCTS).each do |product|
    p_id = product[1][0]
    sales = product[1][1]
    row = ContSpec.find_or_create_by_product_id_and_name(p_id,"bestseller_store_sales")
    row.update_attributes(:value => sales)
  end
  
  end_time = Time.now
  p "Time taken (s) for all files: "+(end_time-start_time).to_s
end
