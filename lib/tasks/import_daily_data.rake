task :get_daily_specs => :environment do
  require 'ruby-debug'
  analyze_daily_raw_specs
end

task :import_daily_attributes => :environment do
  # get historical data on raw product attributes data and write to daily specs
  raw = true
  import_data(raw)
end

task :import_daily_factors => :environment do
  # get historical factors data and write to daily specs
  raw = false
  import_data(raw)
end

def import_data(raw)
  #runs on Maria's iMac:
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
  # import it into the temp database, then get attributes for and write them to DailySpecs
  Dir.foreach(directory) do |snapshot|
    if snapshot =~ /\.sql/
      date = Date.parse(snapshot.chomp(File.extname(snapshot)))
      puts 'making records for date ' + date.to_s
      # import data from the snapshot to the temp database
      puts "mysql -u marc -p keiko2010 -h jaguar temp < #{directory}/#{snapshot}"
      %x[mysql -u marc -p keiko2010 -h jaguar temp < #{directory}/#{snapshot}]

      #username and password cannot be company's (optemo, tiny******)
      ActiveRecord::Base.establish_connection(:adapter => "mysql2", :database => "temp", :host => "jaguar",
        :username => "marc", :password => "keiko2010")
      case raw
      when true
        specs = get_instock_attributes()
      when false
        specs = get_instock_factors()
      end
      ActiveRecord::Base.establish_connection(:development)
      update_daily_specs(date, specs, raw)
    end
  end
end

# collects factor values for instock cameras
# assumes an active connection to the temp database 
# output: an array of hashes of the selected factors, one entry per product
def get_instock_factors()
  
  specs = []
  
  #instock = Product.find_all_by_product_type_and_instock("camera_bestbuy", 1)
  
  instock.each do |p|
    
    sku = p.sku
    pid = p.id
    price_factor = ContSpec.find_by_product_id_and_name(pid,"price_factor")
    maxresolution_factor = ContSpec.find_by_product_id_and_name(pid,"maxresolution_factor")
    opticalzoom_factor = ContSpec.find_by_product_id_and_name(pid,"opticalzoom_factor")
    
    # if any of the expected features do not have values in the DB, don't create a new spec for that product
    if maxresolution_factor.nil? or opticalzoom_factor.nil? or price_factor.nil?
      print "found nil factors for "
      print pid
      next
    end

    # The onsale and featured factor data in ContSpecs was not consistently computed, so has to be recomputed
    # calculate featured factor
    featured_spec = BinSpec.find_by_product_id_and_name(pid, "featured")
    if featured_spec.nil?
      featured_factor = 0
    else
      featured_factor = 1
    end
    # calculate onsale factor
    regularprice_spec = ContSpec.find_by_product_id_and_name(pid, "price")
    saleprice_spec = ContSpec.find_by_product_id_and_name(pid, "saleprice")
    if (regularprice_spec.nil? or saleprice_spec.nil?)
      print
      next
    else
      regularprice = regularprice_spec.value
      saleprice = saleprice_spec.value
    end
    
    onsale_factor = (regularprice > saleprice ? (regularprice - saleprice)/regularprice : 0)

    new_spec = {:sku => sku, :price_factor => price_factor.value, :maxresolution_factor => maxresolution_factor.value, 
      :opticalzoom_factor => opticalzoom_factor.value, :onsale_factor => onsale_factor, :featured_factor => featured_factor}
    specs << new_spec
  end
  return specs
end

# collects values of certain specs for instock cameras
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
      new_spec = {:sku => sku, :saleprice => saleprice.value, :brand => brand.value, :product_type => saleprice.product_type}
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

####ORIGINAL CODE ######
#def get_instock_attributes()
#  specs = []
#  
#  instock = Product.find_all_by_product_type_and_instock("camera_bestbuy", 1)
#  instock.each do |p|
#    sku = p.sku
#    pid = p.id
#    saleprice = ContSpec.find_by_product_id_and_name(pid,"saleprice")
#    maxresolution = ContSpec.find_by_product_id_and_name(pid,"maxresolution")
#    opticalzoom = ContSpec.find_by_product_id_and_name(pid,"opticalzoom")
#    #orders = ContSpec.find_by_product_id_and_name(pid,"orders")
#    brand = CatSpec.find_by_product_id_and_name(pid,"brand")
#    
#    # if any of the expected features do not have values in the DB, don't create a new spec for that product
#    if maxresolution.nil? or opticalzoom.nil? or brand.nil?
#      print "found nil raw features for "
#      print pid
#      next
#    end
#    # featured and onsale may be nil when the value is not missing value but should be of 0
#    featured = BinSpec.find_by_product_id_and_name(pid,"featured") # if nil -> 0, else value
#    onsale = BinSpec.find_by_product_id_and_name(pid,"onsale")
#    featured = featured.nil? ? 0 : 1
#    onsale = onsale.nil? ? 0 : 1
#    
#    new_spec = {:sku => sku, :saleprice => saleprice.value, :maxresolution => maxresolution.value, 
#      :opticalzoom => opticalzoom.value, :orders => orders.value, :brand => brand.value, 
#      :featured => featured, :onsale => onsale}
#    
#    specs << new_spec
#  end
#  return specs
#end

def update_daily_specs(date, specs, raw)
  specs.each do |attributes|
    sku = attributes[:sku]
    if raw == true
      add_daily_spec(sku, "cont", "saleprice", attributes[:saleprice], attributes[:product_type], date)
      add_daily_spec(sku, "cat", "brand", attributes[:brand], attributes[:product_type], date)
    end
  end
end

####ORIGINAL CODE ######
#def update_daily_specs(date, specs, raw)
#  product_type = "camera_bestbuy"
#  specs.each do |attributes|
#    sku = attributes[:sku]
#    if raw == true
#      add_daily_spec(sku, "cont", "saleprice", attributes[:saleprice], product_type, date)
#      add_daily_spec(sku, "cont", "maxresolution", attributes[:maxresolution], product_type, date)
#      add_daily_spec(sku, "cont", "opticalzoom", attributes[:opticalzoom], product_type, date)
#      add_daily_spec(sku, "cont", "orders", attributes[:orders], product_type, date)
#      add_daily_spec(sku, "cat", "brand", attributes[:brand], product_type, date)
#      add_daily_spec(sku, "bin", "featured", attributes[:featured], product_type, date)
#      add_daily_spec(sku, "bin", "onsale", attributes[:onsale], product_type, date)
#    elsif raw == false
#      add_daily_spec(sku, "cont", "price_factor", attributes[:price_factor], product_type, date)
#      add_daily_spec(sku, "cont", "maxresolution_factor", attributes[:maxresolution_factor], product_type, date)
#      add_daily_spec(sku, "cont", "opticalzoom_factor", attributes[:opticalzoom_factor], product_type, date)
#      add_daily_spec(sku, "cont", "onsale_factor", attributes[:onsale_factor], product_type, date)
#      add_daily_spec(sku, "cont", "featured_factor", attributes[:featured_factor], product_type, date)
#    end
#  end
#end

def add_daily_spec(sku, spec_type, name, value, product_type, date)
  case spec_type
  when "cont"
    ds = DailySpec.new(:spec_type => spec_type, :sku => sku, :name => name, :value_flt => value, :product_type => product_type, :date => date)
  when "cat"
    ds = DailySpec.new(:spec_type => spec_type, :sku => sku, :name => name, :value_txt => value, :product_type => product_type, :date => date)
  when "bin"
    ds = DailySpec.new(:spec_type => spec_type, :sku => sku, :name => name, :value_bin => value, :product_type => product_type, :date => date)
  end
  ds.save
end

def analyze_daily_raw_specs
  product_type = "camera_bestbuy"
  output_name =  "./log/Daily_Data/raw_specs.txt"
  out_file = File.open(output_name,'w')
  
  factors = get_cumulative_data(product_type)

  factors.keys.each do |date|
    # for each date appearing in the factors and each sku
    # query the database to get historical attributes stored in daily specs
    factors[date].each do |daily_product|
      sku = daily_product["sku"]
      feature_records = DailySpec.find_all_by_date_and_sku(date, sku)
      if feature_records.empty?
        next
      end
      feature_records.each do |record|
        value = 
        case record.spec_type
          when "cat"
            record.value_txt.sub(/ /, '_')
          when "bin"
            record.value_bin == true ? 1 : 0
          when "cont"
            record.value_flt
        end
        daily_product[record.name] = value
      end
      # output a specification of the product to file
      output_line = [
        date,
        sku,
        daily_product["daily_sales"],
        daily_product["saleprice"],
        daily_product["maxresolution"],
        daily_product["opticalzoom"],
        daily_product["brand"],
        daily_product["featured"],
        daily_product["onsale"],
        product_type
      ].join(" ")
      out_file.write(output_line + "\n")
    end
  end
end

# Use the cumulative data file and extract factor values for products of the type given as input
def get_cumulative_data(product_type)
  factors = {}
  data_path =  "./log/Daily_Data/"
  fname = "Cumullative_Data.txt"
  f = File.open(data_path + fname, 'r')
  lines = f.readlines
  lines.each do |line|
    if line =~ /#{product_type}/
      a = line.split
      date = a[0]
      factors[date] = [] if factors[date].nil?
      factors[date] << {"sku" => a[1], "utility" => a[2], "daily_sales" => a[3], "product_type" => a[4], "saleprice_factor" => a[5], "maxresolution_factor" => a[6], "opticalzoom_factor" => a[7], "brand_factor" => a[8], "onsale_factor" => a[9], "orders_factor" => a[10]}
    end
  end
  return factors
end