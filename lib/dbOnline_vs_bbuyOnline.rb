TESTFILE = "/Users/marc/Documents/Best_Buy_Data/second_set/B_20111216_20111231.csv"

def check_db_online_sales_match_bbuy_file() 
  require 'date'
  
  csvfile = File.new(TESTFILE)
  months_sales = {}
  other_sales = {}
  
  file_dates = /(\d{8})_(\d{8})\.\w{2,3}$/.match(TESTFILE)
  month = Date.strptime($1, '%Y%m%d')..Date.strptime($2, '%Y%m%d')
  
  File.open(csvfile, 'r') do |f|
    f.each do |line|
      m = /^[^0]\d+,\d+,(\d+),(-?\d+),\d+\.?\d*,(\d+).*/.match(line)
      if m != nil
        sku = $1
        sales = $2
        date = Date.strptime($3, '%Y%m%d')
        #check if date falls within timeframe of file
        if month === date
          #create a new key value pair for the given date if it does not already exist
          unless months_sales.key?(date)
            months_sales[date] = Hash.new()
          end
          #if the given date already has the specified sku/sales number stored, add the new sales number to the previous one
          if months_sales[date].key?(sku)
            new_order = months_sales[date][sku].to_i() + sales.to_i()
            months_sales[date].store(sku,new_order.to_s())
          else  
            months_sales[date].store(sku,sales)
          end
        else
          unless other_sales.key?(date)                      #this is almost a repetition of the corresponding
            other_sales[date] = Hash.new()                   # 'if' above. Is there some way to avoid this? 
          end
          if other_sales[date].key?(sku)
            new_order = other_sales[date][sku].to_i() + sales.to_i()
            other_sales[date].store(sku,new_order.to_s())
          else  
            other_sales[date].store(sku,sales)
          end
        end
        
      end
    end
  end 
  
  other_sales_number = count_products_sold(other_sales)
  months_sales_number = count_products_sold(months_sales)
  total = other_sales_number + months_sales_number
  percent_other = 100.0*other_sales_number/total
  percent_months = 100.0*months_sales_number/total
  transactions = count_lines
  
  puts "File directory and name: #{TESTFILE}"
  puts "Products sold outside file's timeframe (#{month}): #{other_sales_number}"
  puts "Percentage of products sold outside of timeframe: #{percent_other}"
  puts "Products sold within file's timeframe (#{month}): #{months_sales_number}"
  puts "Percentage of products sold within timeframe: #{percent_months}"
  puts "Total products sold in file: #{total}"
  puts "\tThis means different products sold in a day, summed over the days in the file"
  puts "Total transactions in file: #{transactions}"
  puts "\tThis is the number of lines in the file that fit the online sale pattern"
  puts "List of days in file not within timeframe: "+other_sales.keys.sort.to_s
  
 # ActiveRecord::Base.establish_connection(:adapter => "mysql2", :database => "daily", :host => "jaguar",
 #   :username => "marc", :password => "keiko2010")
 # debugger
 # online_sales.each do |date|
 #   prods_available = DailySpec.where(:date => date, :name => "orders")
 #   
 #   date[1].each_pair do |sku,sales|
 #     match = prods_available.select {|f| f.sku == sku && f.value_flt == sales}
 #     unless match.empty?
 #       matches +=1
 #     end
 #   end
 #   
 # end
    
end

def count_products_sold (input_hash)
  prods_sold = 0
  input_hash.each_pair do |day,sales|
    prods_sold += sales.length
  end
  return prods_sold
end

def count_lines 
  count = 0
  csvfile = File.new(TESTFILE)
  
  File.open(csvfile, 'r') do |f|
    f.each do |line|
       m = /^[^0]/.match(line)
        # Only continue if line correctly parsed  
        if /^[^0]/.match(line)      
        #if m != nil
          count += 1
        end
    end
  end
  return count
end