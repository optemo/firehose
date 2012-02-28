#example call: bundle exec rake save_instore_daily_sales["20110801","20110831","/Users/marc/Documents/Best_Buy_Data/second_set"]
task :save_instore_daily_sales, [:start_date, :end_date, :directory] => :environment do |t, args|
  save_instore_daily_sales(Date.strptime(args.start_date, '%Y%m%d'), Date.strptime(args.end_date, '%Y%m%d'), args.directory)
end

# Finds all instock products for each day of a given month, looks up the daily sales for these products in the 
# files sent by bestbuy (.csv), stores the daily sales in the all_daily_spec table (firehose_development)
def save_instore_daily_sales (start_date, end_date, directory)
  require 'date'
  month_sales = {}
  start_time = Time.now
  
  newfile = "/Users/marc/Documents/cumullative_data.txt"
  
  Dir.foreach(directory) do |file|
    month_sales = {}  
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
          
      # GET ALL INSTOCK ITEM SKUS/DATES FOR THE MONTH IN QUESTION FROM ALL_DAILY_SPEC TABLE
        # Uncomment this line (and comment line below) to write products sold to a file
        #instock = AllDailySpec.select("sku,date").where(:name=>"store_orders", :value_flt=>(1..9999), :date=>month).order(:date)
        instock = AllDailySpec.select("sku,date").where(:name=>"price", :date=>month).order(:date)
        # Create a hash of {date=>{sku=>0}} to later store sales numbers
        instock.each do |product|
          date = product.date
          #create new date key unless it already exists
          unless month_sales.key?(date)
            month_sales[date] = Hash.new()
          end
          month_sales[date].store(product.sku,0)
        end
        
      #  Function to write all instock products sold to a file 
      #  File.open(newfile, 'a') do |f|
      #    instock.each do |product|
      #      date = product.date.strftime("%d %b %Y")
      #      f.puts "#{date}\t#{product.sku}"
      #      
      #    end
      #  end
       
      # GO THROUGH THE FILE, ONLY ADDING PRODUCTS IN MONTH_SALES HASH MADE ABOVE
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
      
      # WRITE SALES NUMBERS FOR PRODUCTS IN ALL_DAILY_SPECS TABLE  
        month_sales.each_pair do |date, product|
          product.each_pair do |sku, orders|
            AllDailySpec.create(:sku => sku, :name => 'store_orders', :spec_type => 'cont', :value_flt => orders, :product_type => 'camera_bestbuy', :date => date)
          end
        end
        after = Time.now
        p "Time taken (s) for sales from #{month}: "+(after-before).to_s
      end
    end
  end
  end_time = Time.now
  p "Time taken (s) for all files: "+(end_time-start_time).to_s
end
