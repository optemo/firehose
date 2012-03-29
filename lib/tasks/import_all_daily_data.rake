task :get_all_daily_specs => :environment do
  require 'ruby-debug'
 # write_instock_skus_into_file ("drive_bestbuy")
  analyze_all_daily_raw_specs("drive_bestbuy")
end

task :import_all_daily_attributes => :environment do
  # get historical data on raw product attributes data and write to daily specs
  raw = true
  import_all_data(raw)
end

task :import_coeffs => :environment do
 insert_regression_coefficient
end
task :get_features => :environment do
  get_all_features
end

def import_all_data(raw)
  directory = "/mysql_backup/slicehost"
  #directory = "/Users/Monir/optemo/mysql_backup"
  
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
      puts "mysql -u monir -p m_222978 -h jaguar temp < #{directory}/#{snapshot}"
      %x[mysql -u monir -pm_222978 -h jaguar temp < #{directory}/#{snapshot}]

      #username and password cannot be company's (optemo, tiny******)
      ActiveRecord::Base.establish_connection(:adapter => "mysql2", :database => "temp", :host => "jaguar",
        :username => "monir", :password => "m_222978")
       specs = get_all_instock_attributes(date)
   
      ActiveRecord::Base.establish_connection(:development)
      update_daily_specs(date, specs, raw)
    end
  end
end


# collects values of all specs for instock product_type
# assumes an active connection to the temp database 
# output: an array of hashes of the selected specs, one entry per product
def get_all_instock_attributes(date)
  specs = []
  product_type="drive_bestbuy"
  cont_specs = get_cont_specs(product_type).reject{|e| e=~/[a-z]+_[factor|fr]/}
  cont_specs.each do |r|
    puts "#{r}"
  end
  cat_specs =  get_cat_specs(product_type).reject{|e| e=~/[a-z]+_[factor|fr]/}
  #cat_specs = cat_specs.reject{|e| e== "imgsurl" | e== "imglurl" | e== "imgmurl" |e== "img150url"}
  cat_specs.each do |r|
    puts "#{r}"
  end
  bin_specs =  get_bin_specs(product_type).reject{|e| e=~/[a-z]+_[factor|fr]/}
  bin_specs.each do |r|
    puts "#{r}"
  end
  
  #instock = Product.find_all_by_instock_and_product_type(1, product_type)
  some_prodcuts = CatSpec.where("name='category' and value= '29583'").map(&:product_id)
  instock = Product.where("id in (?) and instock = ?",some_products,1)
  
  instock.each do |p|
    sku = p.sku
    pid = p.id
    ContSpec.find_all_by_product_id(pid).each do |row|
      if (cont_specs.include?(row.name))
        specs << {sku: sku, name: row.name, spec_type: "cont", value_flt: row.value, product_type: row.product_type, date: date}   
      end
    end
    
    CatSpec.find_all_by_product_id(pid).each do |row|
      if (cat_specs.include?(row.name))
        specs << {sku: sku, name: row.name, spec_type: "cat", value_txt: row.value, product_type: row.product_type, date: date}
      end
    end
    
    BinSpec.find_all_by_product_id(pid).each do |row|
      if (bin_specs.include?(row.name))
          row.value = 0 if row.value == nil  
          specs << {sku: sku, name: row.name, spec_type: "bin", value_bin: row.value, product_type: row.product_type, date: date}
      end
    end

  end
  return specs
end

def get_cont_specs(product_type="camera_bestbuy")
  @cont_specs||= ContSpec.find_by_sql("select DISTINCT name from cont_specs where product_type= '#{product_type}'").map(&:name)
end

def get_cat_specs(product_type="camera_bestbuy")
  
  @cat_specs||= CatSpec.find_by_sql("select DISTINCT name from cat_specs where product_type= '#{product_type}'").map(&:name)
end

def get_bin_specs(product_type="camera_bestbuy")
  @bin_specs||= BinSpec.find_by_sql("select DISTINCT name from bin_specs where product_type= '#{product_type}'").map(&:name)
end


def update_daily_specs(date, specs, raw)
  alldailyspecs= []
  specs.each do |attributes|
     alldailyspecs << AllDailySpec.new(attributes)
  end
  AllDailySpec.import alldailyspecs
end

def analyze_all_daily_raw_specs(product_type="camera_bestbuy")

  output_name =  "/Users/Monir/optemo/data_analysis/Drive_bestbuy/raw_data_29583_1.txt"
  out_file = File.open(output_name,'w')
  daily_product ={}
  sku = ""
  features = get_all_features()
  features.delete("title")
  features.delete("model")
  features.delete("mpn")
  features.delete("imgsurl")
  features.delete("imgmurl")
  features.delete("imglurl")
  features.delete("img150url")
  out_file.write("date sku "+ features.keys.join(" ") + "\n")
  days= AllDailySpec.where("date >= ? and date <= ?", '2011-08-01', '2011-12-31').select("Distinct(date)").order("date")
  
  days.each do |day|
   puts "day #{day.date}"  
   all_records = AllDailySpec.where("date = ?",day.date)
   puts "all_records_size #{all_records.size}"
     date = day.date
     grouped_sku = all_records.group_by(&:sku)
     grouped_sku.each do |skus, k|
       sku = skus
       daily_product ={}
       k.each do |record_sub|
         value = 
         case record_sub.spec_type
           when "cat"
             record_sub.value_txt.gsub(/\s+/, '_')
           when "bin"
             record_sub.value_bin == true ? 1 : 0
           when "cont"
             record_sub.value_flt
         end
         daily_product[record_sub.name] = value
       end
       # output a specification of the product to file
       output_line= [date, sku]
        output_line = features.keys.inject(output_line){|res,ele| res<< (daily_product[ele]||features[ele])}.join(" ")
        out_file.write(output_line + "\n")
     end
  end
  
end

def get_all_cumulative_data(product_type, features)
  
  factors = {}
  data_path =  "./log/Daily_Data/"
  fname = "cumullative_data_#{product_type}_1.txt"
  f = File.open(data_path + fname, 'r')
  lines = f.readlines
  lines.each do |line|
      a = line.split
      date = Date.parse(a[0])
      #puts "date_analyize #{date}"
      factors[date] = [] if factors[date].nil?
      factors[date] << {"sku" => a[1]}.merge(features)
  end
  return factors
end

def get_all_features
  features={}
  # when we want to get the features of a specific subcategory of a product_type
   products = AllDailySpec.find_by_sql("select distinct sku from all_daily_specs where name= 'category' and value_txt='29583'").map(&:sku)
   skus = products.join(", ")
   #puts "skus #{skus}"
   cont_sp= AllDailySpec.find_by_sql("select DISTINCT name from all_daily_specs where sku in (#{skus}) and spec_type= 'cont'").map(&:name)
    cont_sp.each do |r|
     features[r] = 0
    end
   cat_sp = AllDailySpec.find_by_sql("select DISTINCT name from all_daily_specs where sku in (#{skus}) and spec_type = 'cat'").map(&:name)
   cat_sp.each do |r|
     features[r]="NAM"
   end
   bin_sp= AllDailySpec.find_by_sql("select DISTINCT name from all_daily_specs where sku in (#{skus}) and spec_type= 'bin'").map(&:name)
   bin_sp.each do |r|
     features[r]=0
   end
 # puts "#{features}"
  features
end

def write_instock_skus_into_file(product_type= "camera_bestbuy")
  output_name =  "../log/Daily_Data/cumullative_data_#{product_type}_1.txt"
  out_file = File.open(output_name,'w')
  records = AllDailySpec.find_by_sql("select * from all_daily_specs where date >= '2011-08-01' and date <= '2011-12-31' and name='store_orders' order by date")
  puts "size #{records.size}"
  records.each do |re|
    line=[]
    line << re.date 
    line << re.sku
    line << re.value_flt
    puts "line #{line.join(" ")}"
    out_file.write(line.join(" ")+"\n")
  end
end

def insert_regression_coefficient
  data_path =  "/Users/Monir/optemo/data_analysis/Camera_bestbuy/Outputs&Inputs/"
  fname = "camera_bestbuy_lr_coeffs_Test5_LR.txt"
  product_type= "B20218"
  f = File.open(data_path + fname, 'r')
  lines = f.readlines
  coeffs =[]
  lines.each do |line|
      a = line.split
      puts "#{a[0]} #{a[1]} #{a[2]} #{a[3]} #{a[4]}"
      coeffs << Facet.new(name: a[0].to_str, feature_type: a[4], used_for: "utility", value: a[3].to_f, active: 1, product_type: product_type)   
      #puts "#{a[0]} #{a[1]} #{a[2]}"
      #coeffs << Facet.new(name: a[0].to_str, feature_type: a[2], used_for: "utility", value: a[1].to_f, active: 1, product_type: product_type)     
  end
  Facet.import coeffs
end
