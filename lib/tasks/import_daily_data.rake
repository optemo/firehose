# FIXME: either set "camera_bestbuy" as a global variable or an input to the task

task :daily_factors => :environment do
  analyze_daily_factors
end

task :daily_sales => :environment do
  require 'daily_sales'
  save_daily_sales
end

def analyze_daily_factors
  product_type = "camera_bestbuy"
  output_name =  "./log/Daily_Data/factors.txt"
  factors = get_cumulative_data(product_type)
  out_file = File.open(output_name,'w')
  factors.keys.each do |date|
    # for each date appearing in the factors and each sku...
    # query the database to get: saleprice, maxresolution, opticalzoom, orders, brand, featured, onsale
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
        daily_product["sales"],
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
  
  # now save these to a text file with each line:
  # date, sku, daily_sales, utility, saleprice, [saleprice_factor], maxresolution, [maxresolution_factor], opticalzoom, [opticalzoom_factor], brand, [brand_factor], featured, onsale, [onsale_factor], orders, [orders_factor], product_type

end

def get_cumulative_data(product_type)
  # read the cumulative data file and extract factor values for products of the type given as input
  factors = {}
  data_path =  "./log/Daily_Data/"
  fname = "Cumullative_Data_Sales.txt"
  f = File.open(data_path + fname, 'r')
  lines = f.readlines
  lines.each do |line|
    if line =~ /#{product_type}/
      a = line.split
      date = a[0]
      factors[date] = [] if factors[date].nil?
      #factors[date] << {"sku" => a[1], "utility" => a[2], "daily_sales" => a[3], "product_type" => a[4], "saleprice_factor" => a[5], "maxresolution_factor" => a[6], "opticalzoom_factor" => a[7], "brand_factor" => a[8], "onsale_factor" => a[9], "orders_factor" => a[10]}
      factors[date] << {"sku" => a[1], "sales" => a[2], "product_type" => a[3]}
    end
  end
  return factors
end

task :import_daily_data => :environment do
  
  directory = "/optemo/snapshots/slicehost"
  # loop over the files in the directory, unzipping gzipped files
  Dir.foreach(directory) do |entry|
    if entry =~ /\.gz/
      %x[gunzip #{directory}/#{entry}]
    end
  end
  # loop over each .sql file
  
  Dir.foreach(directory) do |snapshot|
    if snapshot =~ /\.sql/
      date = Date.parse(snapshot.chomp(File.extname(snapshot)))
      puts 'making records for date' + date.to_s
      # ruby date < = > 
      
      # import data from the snapshot to the temp database
      puts "mysql -u oana -pcleanslate -h jaguar temp < #{directory}/#{snapshot}"
      %x[mysql -u oana -pcleanslate -h jaguar temp < #{directory}/#{snapshot}]
      
      ActiveRecord::Base.establish_connection(:adapter => "mysql2", :database => "temp", :host => "jaguar",
        :username => "oana", :password => "cleanslate")
      specs = get_instock_attributes()
      ActiveRecord::Base.establish_connection(:development)
      update_daily_specs(date, specs)
    end
  end
end  

# collects certain specs for instock cameras
# assumes an active connection to the temp database 
# output: an array of hashes of the selected specs, one entry per product
def get_instock_attributes()
  puts ActiveRecord::Base.connection # for debugging
  
  specs = []
  instock = Product.find_all_by_product_type_and_instock("camera_bestbuy", 1)
  instock.each do |p|
    sku = p.sku
    pid = p.id
    saleprice = ContSpec.find_by_product_id_and_name(pid,"saleprice")
    maxresolution = ContSpec.find_by_product_id_and_name(pid,"maxresolution")
    opticalzoom = ContSpec.find_by_product_id_and_name(pid,"opticalzoom")
    orders = ContSpec.find_by_product_id_and_name(pid,"orders")
    brand = CatSpec.find_by_product_id_and_name(pid,"brand")
    
    # if any of the expected features do not have values in the DB, don't create a new spec for that product
    if maxresolution.nil? or opticalzoom.nil? or orders.nil? or brand.nil?
      next
    end
    
    # featured and onsale may be nil when the value is not missing value but should be of 0
    featured = BinSpec.find_by_product_id_and_name(pid,"featured") # if nil -> 0, else value
    onsale = BinSpec.find_by_product_id_and_name(pid,"onsale")
    featured = featured.nil? ? 0 : 1
    onsale = onsale.nil? ? 0 : 1
    
    new_spec = {:sku => sku, :saleprice => saleprice.value, :maxresolution => maxresolution.value, 
      :opticalzoom => opticalzoom.value, :orders => orders.value, :brand => brand.value, 
      :featured => featured, :onsale => onsale}
    specs << new_spec
  end
  return specs
end

def update_daily_specs(date, specs)
  puts ActiveRecord::Base.connection
  product_type = "camera_bestbuy"
  # FIXME: refactor the code below
  specs.each do |attributes|
    sku = attributes[:sku]
    saleprice = attributes[:saleprice]
    maxresolution = attributes[:maxresolution]
    opticalzoom = attributes[:opticalzoom]
    orders = attributes[:orders]
    brand = attributes[:brand]
    featured = attributes[:featured]
    onsale = attributes[:onsale]
    
    # continuous features
    ds = DailySpec.new(:spec_type => "cont", :sku => sku, :name => "saleprice", :value_flt => saleprice, :product_type => product_type, :date => date)
    ds.save
    ds = DailySpec.new(:spec_type => "cont", :sku => sku, :name => "maxresolution", :value_flt => maxresolution, :product_type => product_type, :date => date)
    ds.save
    ds = DailySpec.new(:spec_type => "cont", :sku => sku, :name => "opticalzoom", :value_flt => opticalzoom, :product_type => product_type, :date => date)
    ds.save
    ds = DailySpec.new(:spec_type => "cont", :sku => sku, :name => "orders", :value_flt => orders, :product_type => product_type, :date => date)
    ds.save
    # categorical features
    ds = DailySpec.new(:spec_type => "cat", :sku => sku, :name => "brand", :value_txt => brand, :product_type => product_type, :date => date)
    ds.save
    # binary features
    ds = DailySpec.new(:spec_type => "bin", :sku => sku, :name => "featured", :value_bin => featured, :product_type => product_type, :date => date)
    ds.save
    ds = DailySpec.new(:spec_type => "bin", :sku => sku, :name => "onsale", :value_bin => onsale, :product_type => product_type, :date => date)
    ds.save
  end
end