task :find_product_sales , [:sku, :start_date , :end_date, :directory] => :environment do |t, args|
  args.with_defaults(:start_date=>"20110801",:end_date=>"20111231",:directory=>"/Users/marc/Documents/Best_Buy_Data/second_set")
  start_date = Date.strptime(args.start_date, "%Y%m%d")
  end_date = Date.strptime(args.end_date, "%Y%m%d")
  find_product_sales(args.sku,start_date,end_date,args.directory)
end

#finds the total sales a particular product has in a given time frame (in terms of files)
def find_product_sales (sku,start_date,end_date,directory) 
  all_sales = ""
  net_sales = 0
  count = 0
  
  Dir.foreach(directory) do |file|
    #only process bestbuy data files
    if file =~ /B_\d{8}_\d{8}\.csv/
      /(\d{8})_(\d{8})\.csv$/.match(file)
      file_start_date = Date.strptime($1, '%Y%m%d')
      file_end_date = Date.strptime($2, '%Y%m%d') 
      #only process files within specified time frame
      if start_date <= file_start_date && end_date >= file_end_date
        csvfile = File.new(directory+"/"+file)
        File.open(csvfile, 'r') do |f|
          f.each do |line|
            m = /^0,\d+,(\d+),(\d+),\d+\.?\d*,(\d+).*/.match(line)
            #only continue if line has format of regex
            if m != nil
              sku_read = $1
              sales = $2.to_i
              #date = Date.strptime($3, '%Y%m%d')
              if sku_read == sku
                all_sales += "+#{sales}"
                net_sales += sales
                count += 1
              end
            end
          end
        end
      end
    end
  end
  
  p "All sales for product #{sku}: #{all_sales}"
  p "Net sales: #{net_sales}"
  p "Number of transactions: #{count}"
  
end