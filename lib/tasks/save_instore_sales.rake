task :save_instore_daily_sales => :environment do
  save_instore_daily_sales()
end

##### SPECIFY DIRECTORY IN WHICH FILES LOCATED #####
DIRECTORY = "/Users/marc/Documents/Best_Buy_Data/second_set"

# Finds all instock products for each day of a given month, looks up the daily sales for these products in the 
# files sent by bestbuy (.csv), stores the daily sales in the all_daily_spec table (firehose_development)
def save_instore_daily_sales
  require 'date'
  month_sales = {}
  start_time = Time.now
  
  Dir.foreach(DIRECTORY) do |file|
    month_sales = {}  
    
    if file =~ /\.csv/
      before = Time.now
      csvfile = File.new(DIRECTORY+"/"+file)
      /(\d{8})_(\d{8})\.csv$/.match(file)
      
      #take these out when testing done
      start_date = Date.strptime($1, '%Y%m%d')
      end_date = Date.strptime($2, '%Y%m%d') 
      month = start_date..end_date
   #   month = Date.strptime($1, '%Y%m%d')..Date.strptime($2, '%Y%m%d') 
          
    # GET ALL INSTOCK ITEM SKUS/DATES FOR THE MONTH IN QUESTION FROM ALL_DAILY_SPEC TABLE
      instock_start = Time.now
      fetch_start = Time.now
      instock = AllDailySpec.select("sku,date").where(:name=>"price", :date=>month).order(:date)
      fetch_end = Time.now
      hash_start = Time.now
      #create a hash of {date=>{sku=>0}} to later store sales numbers
      instock.each do |product|
        date = product.date
        #create new date key unless it already exists
        unless month_sales.key?(date)
          month_sales[date] = Hash.new()
        end
        month_sales[date].store(product.sku,0)
      end
      hash_end = Time.now
      instock_end = Time.now
      p "Time taken (s) for select: "+(fetch_end-fetch_start).to_s
      p "Time taken (s) for hash: "+(hash_end-hash_start).to_s
      p "Time taken (s) for instock: "+(instock_end-instock_start).to_s
      
      
    # GO THROUGH THE FILE, ONLY ADDING PRODUCTS IN MONTH_SALES HASH MADE ABOVE
      file_start = Time.now
      File.open(csvfile, 'r') do |f|
        f.each do |line|
          m = /^0,\d+,(\d+),(\d+),\d+\.?\d*,(\d+).*/.match(line)
          #only continue if line has format of regex
          if m != nil
            sku = $1
            sales = $2.to_i
            date = Date.strptime($3, '%Y%m%d')
            #only add sales that occurred within the timeframe demanded
            if month_sales.key?(date)
              #only add the sales of items instock/wanted
              if month_sales[date].key?(sku)
                new_order = month_sales[date][sku] + sales
                month_sales[date].store(sku,new_order)
              end
            end
          end
        end
      end
      file_end = Time.now
      p "Time taken (s) for file: "+(file_end-file_start).to_s
      
    # WRITE SALES NUMBERS FOR PRODUCTS IN ALL_DAILY_SPECS TABLE  
      specs_start = Time.now
      month_sales.each_pair do |date, product|
        product.each_pair do |sku, orders|
            AllDailySpec.create(:sku => sku, :name => 'store_orders', :spec_type => 'cont', :value_flt => orders, :product_type => 'camera_bestbuy', :date => date)
        end
      end
  
  #  # Test for larger scale application (only do first day of month) -> took 260s total for three days (Aug 1, Nov 1, Dec 16)
  #    month_sales[start_date].each do |sku,orders|
  #      AllDailySpec.create(:sku => sku, :name => 'store_orders', :spec_type => 'cont', :value_flt => orders, :product_type => 'camera_bestbuy', :date => start_date)
  #    end
 
  #   # For testing row creation and changing through the files in the directory
  #     debugger
  #     date = start_date
  #     sku = '10164411' #all sales      # all zero sales : sku = '10140246'
  #     orders = month_sales[date][sku]
  #     AllDailySpec.create(:sku => sku, :name => 'store_orders', :spec_type => 'cont', :value_flt => orders, :product_type => 'camera_bestbuy', :date => date)
  #     sleep(1)
  
      specs_end = Time.now
      p "Time taken (s) for table: "+(specs_end-specs_start).to_s
 
      after = Time.now
      p "Time taken (s) for sales from #{month}: "+(after-before).to_s
    end
  end
  end_time = Time.now
  p "Time taken (s) for all files: "+(end_time-start_time).to_s
end