#************************************************#
#****************SET FILE TO TEST****************#
#************************************************#

# Specify directory of file to test
TESTFILE = "/Users/marc/Documents/Best_Buy_Data/second_set/F_20111216_20111231.csv"
  # Old file: "/optemo/BestBuy_Data/B_20101201_20101215.csv"
  # New File: "/optemo/BestBuy_Data/Store_Data/B_20101201_20101216.csv"

# Finds all purchases in which more than one item of the same item was bought/returned
def bb_multiple_same_items_same_purchase
  require 'date'
  
  erroneous_lines = []
  multi_item_purchases = {} #hash {date => {sku => num_sold}}
  date_obj = Date.new() 
  count = 0
  csvfile = File.new(TESTFILE)
  
  File.open(csvfile, 'r') do |f|
    # Reads the first date in the file. If the option below is chosen, all products sold before this date will be discounted
    line = f.readline
    m = /.+,[.0-9]+,\s*\d+,[-0-9]+.*,(\d+).*,[.0-9]+.*,[BF]/.match(line)
    start = Date.strptime(m[1], '%Y%m%d')
    
    f.each do |line|
      m = /[.0-9]+,[.0-9]+,\s*(\d+),([-0-9]+),[.0-9]+,(\d+).*,[.0-9]+,[BF]/.match(line)
        # Only continue if line correctly parsed
        if m != nil
          # Only continue if more than one of the same item bought/returned
          unless (-1..1) === m[2].to_i()
            sku = m[1]
            num_sold = m[2]
            date = m[3]
            date_obj = Date.strptime(date, '%Y%m%d')
            
            #******** Uncomment this if you only want the month's duplicates. ********#
            #******** Excludes previous month's trailers. Assumes first entry has first day as date. ********#
            unless date_obj <= start
            
              # If the date already exists in the hash the program moves on. If it does not, a new hash for the date is made here
              unless multi_item_purchases.key?(date_obj)
                multi_item_purchases[date_obj] = Hash.new()
              end
              # Multiple twin items sold in same day but in different orders appear as #+#, where each '#' is a different order's number of producst.
              if multi_item_purchases[date_obj].key?(sku)
                new_order = multi_item_purchases[date_obj][sku] + "+" + num_sold
                multi_item_purchases[date_obj].store(sku,new_order)
                count += 1
              else  
                multi_item_purchases[date_obj].store(sku,num_sold)
                count += 1
              end
              
            end   #******* Uncomment for last month's exclusion *******#
          
          end
        # Double check for problematic lines for reg. exp.
        else
          print "\nLine Not Properly Parsed: "+line
          erroneous_lines.push(line)
        end
    end
  end
  
  print "\nFile path: "+csvfile.path()
  print "\nNumber of Twin Item Purchases: "+ count.to_s() + "\n\n"
  # debugger
  "The Data is available in the 'multi_item_purchases' hash in the function. Otherwise, quit debugger (q)"
end

# Searches a BestBuy/FutureShop file and extracts the unique store ids
def diff_store_ids
  
  store_ID = 0
  store_ids = []
  erroneous_lines = []
  csvfile = File.new(TESTFILE)

  File.open(csvfile, 'r') do |f|
    f.each do |line|
      m = /.+\s*\d+,[-0-9]+.*,([.0-9]+).+/.match(line)
        # Only continue if line correctly parsed
        if m != nil   
          store_ID = m[1]
          unless store_ids.include?(store_ID)
            store_ids.push(store_ID)
          end
        # Double check for problematic lines for reg. exp.
        else
          print "\nLine Not Properly Parsed: "+line
          erroneous_lines.push(line)
        end
    end
  end
  
  print "\nFile path: "+csvfile.path()
  print "\nNumber of Stores: "+store_ids.size().to_s()
  
  "The data is available in the 'store_ids' array in the function. Otherwise, quit debugger (q)" 
end

# Function finds all purchases in file that have 0 as the sale price
def find_zeroes
  zero_price_purchases = []
  current_transaction = []
  erroneous_lines = []
  csvfile = File.new(TESTFILE)
  
  File.open(csvfile, 'r') do |f|
    f.each do |line|
      m = /[.01-9]+,([-.0-9]+),\s*(\d+),([-.01-9]+),([.01-9]+),(\d+).*,([.0-9]+).+/.match(line)
        # Only continue if line correctly parsed
        if m != nil   
          if (m[4]=="0")
            current_transaction = [m[1],m[2],m[3],m[5],m[6]]
            zero_price_purchases.push(current_transaction)
          end
        # Double check for problematic lines for reg. exp.
        else
          print "\nLine Not Properly Parsed: "+line
          erroneous_lines.push(line)
        end
    end
  end
  
  print "\nFile path: "+csvfile.path()
  print "\nNumber of Invalid Sales: "+ zero_price_purchases.length().to_s()
  
  "The Data is available in the 'zero_price_purchases' array in the function. Otherwise, quit debugger (q)"
end

# Finds all unique purchase ids. Assumes that no purchase id can be used non-consecutively (unique to a single purchase)
def unique_purchase_ids
  purchase_ids = []
  erroneous_lines = []
  previous_id = -1
  csvfile = File.new(TESTFILE)
  
  File.open(csvfile, 'r') do |f|
    f.each do |line|
      m = /\d+,([.0-9]+).+/.match(line)
        # Only continue if line correctly parsed
        if m != nil   
          id = m[1]
          unless id == previous_id
            purchase_ids.push(id)
          end
          previous_id = id
        # Double check for problematic lines for reg. exp.
        else
          print "\nLine Not Properly Parsed: "+line
          erroneous_lines.push(line)
        end
    end
  end
  
  print "\nFile path: "+csvfile.path()
  print "\nNumber of Separate Sales: "+ purchase_ids.length().to_s()
  
  "The Data is available in the 'purchase_ids' array in the function. Otherwise, quit debugger (q)"
end
#Displays the number of lines in the file. This corresponds to the number of transactions completed. A transaction here 
#is considered as buying one or many of the same product (this counts as one transaction). Combined purchases are considered
#separate transactions (ie: buying a tv and a laptop is 2 transactions, buying 2 of the same tv is one transaction)
def count_lines()
  count = 0
  csvfile = File.new(TESTFILE)
  
  File.open(csvfile, 'r') do |f|
    f.each do |line|
      #although this check is technically unnecessary, it may be good to keep as a safety that the file format has not changed
   #   m = /\d+,([.0-9]+).+/.match(line)
   #     # Only continue if line correctly parsed
   #     if m != nil   
           count += 1
   #     # Double check for problematic lines for reg. exp.
   #     else
   #       print "\nLine Not Properly Parsed: "+line
   #       erroneous_lines.push(line)
   #     end
    end
  end
  
  print "\nFile path: "+csvfile.path()
  print "\nNumber of Different Products Sold: "+ count.to_s()+"\n"
end


def find_out_of_month_sales
  previous_sales = {}
  count = 0
  csvfile = File.new(TESTFILE)
  
  file_dates = /(\d{8})_(\d{8})\.\w{2,3}$/.match(TESTFILE)
  month = Date.strptime($1, '%Y%m%d')..Date.strptime($2, '%Y%m%d')
  
  File.open(csvfile, 'r') do |f|
    f.each do |line|
      m = /\d+,(\d+).+,(\d+),[0-9.]+,[BF]$/.match(line)
      if m != nil
        purchase_id = $1
        date = Date.strptime($2, '%Y%m%d')
        #check if date falls within timeframe of file
        unless month === date
          #create a new key value pair for the given date if it does not already exist
          unless previous_sales.key?(date)
            previous_sales[date] = Array.new()
          end
          unless previous_sales[date].include? (purchase_id)
            previous_sales[date].push(purchase_id)
            count += 1
          end
        end
      end
    end
  end
  
  print "\nFile path: "+csvfile.path()
  print "\nNumber of Separate, Out of Month Sales: #{count}"
  
  "The Data is available in the 'previous_sales' hash in the function. Otherwise, quit debugger (q)"
end

def find_sku_length (length)
  count = 0
  wanted_skus = {}
  csvfile = File.new(TESTFILE)
  
  File.open(csvfile, 'r') do |f|
    f.each do |line|
      m = /^\d+,\d+,(\d+).+/.match(line)
      if m != nil && m[1].length == length
        count += 1
        sku = m[1]
        if wanted_skus.include?(sku)
          wanted_skus[sku][0] += 1
          wanted_skus[sku][1].push(line)
        else
          wanted_skus[sku] = [1,[line]]
        end
      end
    end
  end
  
  print "\nFile path: "+csvfile.path()
  print "\nNumber of skus of length #{length}: #{count}"
  
  "The Data is available in the 'wanted_skus' hash in the function. Otherwise, quit debugger (q)"
end