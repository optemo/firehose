#************************************************#
#****************SET FILE TO TEST****************#
#************************************************#

# Specify directory of file to test
TESTFILE = "/optemo/BestBuy_Data/F_20101201_20101215.csv"
  # Old file: "/optemo/BestBuy_Data/B_20101201_20101215.csv"
  # New File: "/optemo/BestBuy_Data/Store_Data/B_20101201_20101216.csv"
  # Other testing: "/Users/marc/Documents/Best_Buy_Data/sample_bestbuy_instore_sale.txt"

#************************************************#
#*********CHOOSE SAVING OPTION AT BOTTOM*********#
#********save all vs. save sold products*********#
#************************************************#

def save_instore_daily_sales
  require 'date'
  
  erroneous_lines = []
  date_obj = Date.new()
  orders_map = {} # map of date => new_hash
  csvfile = File.new(TESTFILE)
  
  print "File Path: "+csvfile.path()
  # Transfer all products in database to array
  dailyspec_skus = DailySpec.select("DISTINCT(sku)") 
  index = 0
  dailyspec_sku_only = Array.new()
  dailyspec_skus.each do |prod_sku|
    sku1 = prod_sku.sku
    dailyspec_sku_only.push(sku1)
    index += 1
  end
  File.open(csvfile, 'r') do |f|
    f.each do |line|
      # Get sku,number_items_sold_in_store and date from file line
      m = /[.0-9]+,[.0-9]+,\s*(\d+),([-0-9]+),[.0-9]+,(\d+).*,[.0-9]+,[BF]/.match(line) 
      # Check that the array m is not nil. Presumably some end-of-file trouble: could not see this due to large file size. (Problem may be successive newlines)
      # Then store parsed data into usable variables
      if m != nil
        sku = m[1]
        # Only adds those products that already exist in the database to the orders_map hash
        if dailyspec_sku_only.include?(sku)
          in_store_sold = m[2]
          date = m[3]
          date_obj = Date.strptime(date, '%Y%m%d')
          # If the date already exists in the hash the program moves on. If it does not, a new hash for the date is made here
          unless orders_map.key?(date_obj)
            orders_map[date_obj] = Hash.new()
          end
          # Checks if the hash already contains a given sku for a date. If so, it adds the new in store sale data to the old
          # Otherwise it simply adds the sku/number sold combo in the hash
          if orders_map[date_obj].key?(sku)
            new_order = orders_map[date_obj][sku].to_i() + in_store_sold.to_i()
            orders_map[date_obj].store(sku,new_order.to_s())
          else  
            orders_map[date_obj].store(sku,in_store_sold)
          end
        end
      else
        print "\nProblematic Line: "+line
        erroneous_lines.push(line)
      end
    end
  end
  
  # For each date key, iterate through the products in the database to add the number of in store sales. A new row in the DailySpec table is created and saved every iteration.
  orders_map.each_pair do |date, sku_order_hash| 
    
    #***************need to add id to write in spec table***************#
    
=begin  
    #***********SAVE ALL***********#
    # Function for regular/current files. If the product is not found in the hash, it's number of sales is defaulted to 0.
    instock = DailySpec.where(:date => date).select("DISTINCT(sku)")
    instock.each do |prod_sku|
    # Add info for each product on that date in daily_spec
    dailyspec_sku_only.each do |prod_sku|
      sku = prod_sku.sku
      product_type = DailySpec.find_by_sku(sku).product_type
      orders_spec = sku_order_hash[sku]
      orders = (orders_spec.nil?) ? "0" : orders_spec
      # Write orders to daily_specs in_store_sales for the date and the sku
      ds = DailySpec.new(:spec_type => "cont", :sku => sku, :name => "in store sales", :value_flt => orders, :product_type => product_type, :date => date)
      ds.save
    end
=end

    #***********SAVE PRODUCTS WITH A NUMBER OF SALES ONLY***********#
    # Function to run if database is incomplete or does not go back to date specified in file. Only saves the saves the non-zero sales products
    for sku in sku_order_hash.keys()
        orders_spec = sku_order_hash[sku] 
        orders = (orders_spec.nil?) ? "0" : orders_spec
        product_type = DailySpec.find_by_sku(sku).product_type
        # Write orders to daily_specs in_store_sales for the date and the sku
        ds = DailySpec.new(:spec_type => "cont", :sku => sku, :name => "in store sales", :value_flt => orders, :product_type => product_type, :date => date)
        ds.save
    end    
  end
end