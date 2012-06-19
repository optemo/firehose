DAYS_BACK = 60

task :catchup_daily_specs,[:start_date,:end_date] => :environment do |t,args|
  # Gets the daily instock products either from daily_specs or from snapshots
  # and then saves online_orders/pageviews for those products into daily_specs
  
  require 'email_data_collection'
  start_date = Date.strptime(args.start_date, "%Y%m%d")
  end_date = Date.strptime(args.end_date, "%Y%m%d")
  (start_date..end_date).each do |date|
    date_str = date.strftime("%Y%m%d")
    before_whole = Time.now
    
    import_instock_data(date,date)
    
    # Load pageviews based on previous day's products (all)
    save_email_data({:first_possible_date => "29-Oct-2011", :spec => "pageviews", :table => "daily_specs"}, false, date, date)
    
    # Load online_orders based on previous day's instock
    save_email_data({:first_possible_date => "09-Sep-2011", :spec => "online_orders", :table => "daily_specs"}, false, date, date)

    # Delete oldest record if daily_specs goes back more than 'DAYS_BACK' days
    dates_saved = DailySpec.select("DISTINCT(date)").order("date ASC").map(&:date)
    unless dates_saved.length <= DAYS_BACK 
      DailySpec.delete_all(:date => dates_saved.first)
    end
    
    after_whole = Time.now
    p "Total time for #{date}: #{after_whole-before_whole} s"
  end
  # Clean up everything more than 60 dates back from daihy_spec
  dates_saved = DailySpec.select("DISTINCT(date)").order("date ASC").map(&:date)
  unless dates_saved.length <= DAYS_BACK 
    DailySpec.delete_all(:date => dates_saved[0, dates_saved.length-DAYS_BACK])
  end
  
end

def import_instock_data(start_date,end_date)
  # FIXME: make sure that the directory here is the right one!!!
  #for local runs (change to own directory)
  #directory = "/optemo/dumps"
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
      date_string = snapshot.gsub(/\D*(\d+).*/,'\1')
      date = Date.parse(date_string)
      
      if (start_date..end_date) === date && DailySpec.where(:name => 'instock', :date => date).limit(1).empty?          
        
        puts 'making instock records for date ' + date.to_s
        
        # import data from the snapshot to the temp database
        
        puts "/usr/bin/mysql -u optemo -p[...] -h jaguar temp < #{directory}/#{snapshot}"
        %x[/usr/bin/mysql -u optemo -p***REMOVED*** -h jaguar temp < #{directory}/#{snapshot}]
        
        # Must be local user's credentials if run locally
        ActiveRecord::Base.establish_connection(:adapter => "mysql2", :database => "temp", :host => "jaguar",
          :username => "oana", :password => "cleanslate")
        
        specs = []
        instock = Product.find_all_by_instock(1)
        instock.each do |p|
          sku = p.sku
          p_cat_spec = CatSpec.where(product_id: p.id, name: "product_type").first
          
          p_type = p_cat_spec.value unless p_cat_spec.nil?
          
          specs.push([sku,'instock','bin',p.instock,p_type,date])
        end
        ActiveRecord::Base.establish_connection(ENV["RAILS_ENV"])
        columns = %W( sku name spec_type value_bin product_type date )
        DailySpec.import(columns,specs)
      end
    end  
  end
end
