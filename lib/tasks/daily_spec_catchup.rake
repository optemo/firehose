DAYS_BACK = 60

# Imports instock products from snapshots, then gets online_orders/pageviews for those products
# Saves data to daily_specs
task :catchup_daily_specs,[:start_date,:end_date] => :environment do |t,args|
  require 'email_data_collection'
 
  start_date = Date.strptime(args.start_date, "%Y%m%d")
  end_date = Date.strptime(args.end_date, "%Y%m%d")
  (start_date..end_date).each do |date|
    date_str = date.strftime("%Y%m%d")
    before_whole = Time.now
    
    # Remove old products from table
    DailySpec.delete_all(:name => 'instock')
 
   # Load products with instock spec (from the day wanted) to DailySpec
    before_import = Time.now
    import_instock_data(date,date)
    after_import = Time.now
    p "Time for snapshot data import for #{date}: #{after_import-before_import}"

    # Load online_orders based on previous day's instock
    save_email_data({:first_possible_date => "09-Sep-2011", :spec => "online_orders", :table => "daily_specs"}, false, date, date)

    # Load pageviews based on previous day's products (all)
    save_email_data({:first_possible_date => "29-Oct-2011", :spec => "pageviews", :table => "daily_specs"}, false, date, date)

    # Delete oldest record if daily_specs goes back more than 'DAYS_BACK' days
    dates_saved = DailySpec.select("DISTINCT(date)").order("date ASC").map(&:date)
    unless dates_saved.length <= DAYS_BACK 
      DailySpec.delete_all(:date => dates_saved.first)
    end
 
    after_whole = Time.now
    p "Total time for #{date}: #{after_whole-before_whole} s"
  end
  
  # Final cleanup of table
  DailySpec.delete_all(:name => 'instock')
end

def import_instock_data(start_date,end_date)
  #for local runs (change to own directory)
  #directory = "/optemo/snapshots/slicehost"
  #for runs on jaguar
  directory = "/mysql_backup/slicehost"
  
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
        puts "mysql -u oana -p[...] -h jaguar temp < #{directory}/#{snapshot}"
        %x[mysql -u oana -pcleanslate -h jaguar temp < #{directory}/#{snapshot}]
        # Must be local user's credentials if run locally
        ActiveRecord::Base.establish_connection(:adapter => "mysql2", :database => "temp", :host => "jaguar",
          :username => "oana", :password => "cleanslate")
        specs = []
        instock = Product.find_all_by_instock(1)
        instock.each do |p|
          sku = p.sku
          specs.push([sku,'instock','bin',p.instock,p.product_type,date])
        end
        ActiveRecord::Base.establish_connection(:production)
        columns = %W( sku name spec_type value_bin product_type date )
        DailySpec.import(columns,specs)
      end
    end
  end
end
