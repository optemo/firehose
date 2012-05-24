task :get_all_daily_specs,[:product_type, :category, :start_date, :end_date] => :environment do |t,args|
  require 'ruby-debug'
  analyze_all_daily_raw_specs(args.product_type,args.category, args.start_date, args.end_date)
end

task :import_all_daily_attributes, [:start_date, :end_date] => :environment do |t, args|
  # get historical data on raw product attributes data and write to daily specs
  import_all_data(Date.strptime(args.start_date, '%Y%m%d'), Date.strptime(args.end_date, '%Y%m%d'))
end

#rake import_coeffs["B20028","/optemo/data_analysis/Drive_bestbuy/Inputs&Outputs/Coefficient_20028_Test4.txt"]
task :import_coeffs, [:product_type, :file_path] => :environment do |t, args|
 insert_regression_coefficient(args.product_type, args.file_path)
end
task :get_features => :environment do
  get_all_features
end

task :delete_some_data  => :environment do
delete_some_categories_data
end
task :svm_light => :environment do
  convert_to_svm_format
end

def import_all_data(start_date, end_date)
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
      if (date >= start_date and date <= end_date)
        puts 'making records for date ' + date.to_s
        # import data from the snapshot to the temp database
        puts "mysql -u oana -pcleanslate -h jaguar temp < #{directory}/#{snapshot}"
        %x[mysql -u oana -pcleanslate -h jaguar temp < #{directory}/#{snapshot}]

        #username and password cannot be company's (optemo, tiny******)
        ActiveRecord::Base.establish_connection(:adapter => "mysql2", :database => "temp", :host => "jaguar",
          :username => "oana", :password => "cleanslate")
         specs = get_all_instock_attributes(date)
   
        ActiveRecord::Base.establish_connection(:development)
        update_all_daily_specs(date, specs)
      end
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
  some_products = CatSpec.where("name='category' and value= '29583'").map(&:product_id)
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


def update_all_daily_specs(date, specs)
  AllDailySpec.delete_all();
  alldailyspecs= []
  specs.each do |attributes|
     alldailyspecs << AllDailySpec.new(attributes)
  end
  AllDailySpec.import alldailyspecs
end

def analyze_all_daily_raw_specs(product_type="camera_bestbuy", category="", start_date= '2011-11-01', end_date='2011-12-31')

  output_name =  "/optemo/data_analysis/Drive_bestbuy/raw_data_#{product_type}#{category}_#{start_date}_#{end_date}.txt"
  out_file = File.open(output_name,'w')
  daily_product ={}
  sku = ""
  features = get_all_features(category)
  features.delete("title")
  features.delete("model")
  features.delete("mpn")
  features.delete("utility")
  features.delete("imgsurl")
  features.delete("imgmurl")
  features.delete("imglurl")
  features.delete("img150url")
  out_file.write("date sku "+ features.keys.join(" ") + "\n")
  days= AllDailySpec.where("date >= ? and date <= ?", start_date, end_date).select("Distinct(date)").order("date")
  
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


def get_all_features(category="20243")
  features={}
  # when we want to get the features of a specific subcategory of a product_type
   products = AllDailySpec.find_by_sql("select distinct sku from all_daily_specs where name= 'category' and value_txt='#{category}'").map(&:sku)
   skus = products.join(", ")
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
  features
end

def insert_regression_coefficient(product_type, file_path)
  f = File.open(file_path, 'r')
  lines = f.readlines
  coeffs =[]
  lines.each do |line|
      a = line.split
      puts "#{a[0]} #{a[1]} #{a[2]} #{a[3]}"
      coeffs << Facet.new(name: a[0].to_str, feature_type: a[3], used_for: "utility", value:(a[1].to_f * (1-a[2].to_f)), active: 1, product_type: product_type)   
  end
  Facet.import coeffs
end

def delete_some_categories_data
  
  skus = AllDailySpec.where("name = 'category' and value_txt in ('20237','20239')").select("DISTINCT(sku)").map(&:sku)
  AllDailySpec.delete_all(["sku in (?)", skus])    
end

#convert a file obtained by  the 'analyze_all_daily_raw_specs' function into svm_light foramt (a format needed for CRR analysis)
def convert_to_svm_format(product_type="camera_bestbuy")
  data_path =  "/Users/optemo/data_analysis/Camera_bestbuy/"
  fname = "df_used_for_CRR_test.txt"
  f = File.open(data_path + fname, 'r')
  output_name =  "/Users/optemo/data_analysis/Camera_bestbuy/#{product_type}_svm_light_format_test.txt"
  out_file = File.open(output_name,'w')
  
  lines = f.readlines
 
  lines.each do |line|
      output = ""
      index =0 
      a = line.split
      puts "#{a}"
      output += a[a.length-1]+" "
      (2..(a.length-2)).each do |e|
        index +=1
        #puts "#{a[e]}"
        output = output + (index.to_s) + ":"+ a[e]+ " " if (a[e].to_f != 0.0)
      end
      out_file.write(output + "\n")      
  end  
end
