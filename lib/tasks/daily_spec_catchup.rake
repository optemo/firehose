# roll together all three: orders, pageviews, instock(snapshot)
# have max 60 days data
#	 every new day added, remove last day
# don't store instock more than need to (previous day's only)

DAYS_BACK = 60

task :catchup_daily_specs,[:start_date,:end_date] => :environment do |t,args|
  require 'daily_sales'
  require 'daily_page_views'
 
  start_date = Date.strptime(args.start_date, "%Y%m%d")
  end_date = Date.strptime(args.end_date, "%Y%m%d")
  (start_date..end_date).each do |date|
    date_str = date.strftime("%Y%m%d")
    before_whole = Time.now
    
    # Remove old products from table
 #   DailySpec.delete_all(:name => 'instock')
 
 #  Eventually remove this (use the above)
    DailySpec.delete_all(:date => date)
 
   # Load products with instock spec (from the day wanted) to DailySpec
    before_import = Time.now
    import_instock_data(date,date)
    after_import = Time.now
    p "Time for snapshot data import for #{date}: #{after_import-before_import}"

    # Load online_orders based on previous day's instock
    if DailySpec.where(:date => date, :name =>'online_orders').empty?
      save_daily_sales("daily_specs",false,date,date) # Use mass inserts
    else
      p "#{date} already has some online_orders saved. Not using mass inserts (slower)..."
      save_daily_sales("daily_specs",true,date,date)
    end
    
    # Load pageviews based on previous day's products (all)
    if DailySpec.where(:date => date, :name =>'pageviews').empty?
      save_daily_pageviews(false,date,date) # Use mass inserts
    else
      p "#{date} already has some pageviews saved. Not using mass inserts (slower)..."
      save_daily_pageviews(true,date,date)
    end
    
 #   # Delete oldest record if daily_specs goes back more than 'DAYS_BACK' days
 #   dates_saved = DailySpec.select("DISTINCT(date)").order("date ASC").map(&:date)
 #   unless dates_saved.length <= DAYS_BACK 
 #     DailySpec.delete_all(:date => dates_saved.first)
 #   end
 
    after_whole = Time.now
    p "Total time for #{date}: #{after_whole-before_whole} s"
  end
end

def import_instock_data(start_date,end_date)
  #for local runs (change to own directory)
  directory = "/optemo/snapshots/slicehost"
  #for runs on jaguar
  #directory = "/mysql_backup/slicehost"
  
  # loop over the files in the directory, unzipping gzipped files
  Dir.foreach(directory) do |entry|
    if entry =~ /\.gz/
      %x[gunzip #{directory}/#{entry}]
    end
  end
  # loop over each daily snapshot of the database (.sql file),
  # if it is in the date range given: import it into the temp database + get instock products
  Dir.foreach(directory) do |snapshot|
    if snapshot =~ /\.sql/
      date = Date.parse(snapshot.chomp(File.extname(snapshot)))
      if (start_date..end_date) === date 
        puts 'making records for date ' + date.to_s
        # import data from the snapshot to the temp database
        puts "mysql -u optemo -p ***REMOVED*** -h jaguar temp < #{directory}/#{snapshot}"
        %x[mysql -u marc -pkeiko2010 -h jaguar temp < #{directory}/#{snapshot}]
        # Must be local user's credentials if run locally
        ActiveRecord::Base.establish_connection(:adapter => "mysql2", :database => "temp", :host => "jaguar",
          :username => "marc", :password => "keiko2010")
        specs = []
        instock = Product.find_all_by_instock(1)
        instock.each do |p|
          sku = p.sku
          specs.push([sku,'instock','bin',p.instock,p.product_type,date])
        end
        ActiveRecord::Base.establish_connection(:development)        
        columns = %W( sku name spec_type value_bin product_type date )
        DailySpec.import(columns,specs)
      end
    end
  end
end
