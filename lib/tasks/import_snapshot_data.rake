# Imports select snapshot data to daily_specs
# Does all snapshots in directory given

task :import_daily_attributes, [:start_date,:end_date] => :environment do |t,args|
  # get historical data on raw product attributes data and write to daily specs
  start_date = Date.strptime(args.start_date, "%Y%m%d")
  end_date = Date.strptime(args.end_date, "%Y%m%d")
  import_data(start_date,end_date)
end

def import_data(start_date,end_date)
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
  # if it is in the date range given:import it into the temp database, then get attributes for and write them to DailySpecs
  Dir.foreach(directory) do |snapshot|
    if snapshot =~ /\.sql/
      date = Date.parse(snapshot.chomp(File.extname(snapshot)))
      if (start_date..end_date) === date 
        puts 'making records for date ' + date.to_s
        # import data from the snapshot to the temp database
        puts "mysql -u optemo -p ***REMOVED*** -h jaguar temp < #{directory}/#{snapshot}"
        %x[mysql -u optemo -p***REMOVED*** -h jaguar temp < #{directory}/#{snapshot}]
        # Must be local user's credentials if run locally
        ActiveRecord::Base.establish_connection(:adapter => "mysql2", :database => "temp", :host => "jaguar",
          :username => "optemo", :password => "***REMOVED***")
        specs = get_instock_attributes()
        ActiveRecord::Base.establish_connection(:development)
        update_daily_specs(date, specs)
      end
    end
  end
end

# collects values of certain specs for instock products
# assumes an active connection to the temp database 
# output: an array of hashes of the selected specs, one entry per product
def get_instock_attributes()
  specs = []
  instock = Product.find_all_by_instock(1)
  instock.each do |p|
    sku = p.sku
    pid = p.id
    saleprice = ContSpec.find_by_product_id_and_name(pid,"saleprice")
    brand = CatSpec.find_by_product_id_and_name(pid,"brand")
    if saleprice != nil && brand != nil
      new_spec = {:sku => sku, :saleprice => saleprice.value, :brand => brand.value, :product_type => p.product_type}
      specs << new_spec
#    elsif brand != nil
#      new_spec = {:sku => sku, :brand => brand.value, :product_type => brand.product_type} 
#    elsif saleprice != nil
#      new_spec = {:sku => sku, :saleprice => saleprice.value, :product_type => saleprice.product_type}
    else
      puts "SKU: #{sku} has no price and/or brand"
    end
#    specs << new_spec
  end
  return specs
end

def update_daily_specs(date, specs)
  specs.each do |attributes|
    sku = attributes[:sku]
    add_daily_spec(sku, "cont", "saleprice", attributes[:saleprice], attributes[:product_type], date)
    add_daily_spec(sku, "cat", "brand", attributes[:brand], attributes[:product_type], date)
  end
end

def add_daily_spec(sku, spec_type, name, value, product_type, date)
  case spec_type
  when "cont"
    ds = DailySpec.find_or_initialize_by_sku_and_name_and_product_type_and_date(sku,name,product_type,date)
    ds.update_attributes(:spec_type => spec_type, :value_flt => value)
    # ds = DailySpec.new(:spec_type => spec_type, :sku => sku, :name => name, :value_flt => value, :product_type => product_type, :date => date)
  when "cat"
    ds = DailySpec.find_or_initialize_by_sku_and_name_and_product_type_and_date(sku,name,product_type,date)
    ds.update_attributes(:spec_type => spec_type, :value_txt => value)
    #ds = DailySpec.new(:spec_type => spec_type, :sku => sku, :name => name, :value_txt => value, :product_type => product_type, :date => date)
  when "bin"
    ds = DailySpec.find_or_initialize_by_sku_and_name_and_product_type_and_date(sku,name,product_type,date)
    ds.update_attributes(:spec_type => spec_type, :value_bin => value)
    #ds = DailySpec.new(:spec_type => spec_type, :sku => sku, :name => name, :value_bin => value, :product_type => product_type, :date => date)
  end
  ds.save
end
