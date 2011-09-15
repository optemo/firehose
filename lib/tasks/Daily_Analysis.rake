

task :daily_data_collection => :environment do
  Session.new
  require 'daily_sales_email'
  read_daily_sales()
  draw_daily_graph()
end  

def draw_daily_graph()
  command="echo 'set term png; set output \"./tmp/Daily_Data/"+Time.now.to_s[0..9]+".png\"; set xlabel \"Utility\"; set ylabel \"Sales\"; plot \"./tmp/Daily_Data/"+Time.now.to_s[0..9]+".txt\" using 2:3 title \""+Time.now.to_s[0..9]+"\"' | gnuplot"
  %x{#{command}}
  command="echo 'set term png; set output \"./tmp/Daily_Data/Cumullative_as_of_"+Time.now.to_s[0..9]+".png\"; set xlabel \"Utility\"; set ylabel \"Sales\"; plot \"./tmp/Daily_Data/Cumullative_Data.txt\" using 3:4 title \""+Time.now.to_s[0..9]+"\"' | gnuplot"
  %x{#{command}}
end


task :generate_graphs => :environment do
  
  x=parse_data()
  
  #generate a temporary data file for gnuplot to print
  
  temp=File.open("temp.txt","w")
  
  count_track=0
  count=0
  
  x.keys.each do |key|
    p=Product.find_by_sku(key)
    if p!=nil
      if p.instock
        u=p.cont_specs.find_by_name("utility")
        if u.value > 1
          print p.sku," ",p.title," has utility ",u.value,"\n"
        end  
        temp.write(u.value.to_s+" "+x[key].to_s+"\n")
        count_track=count_track+1
      end  
    end
    count=count+1
  end
  temp.close()
  
  #percentage of daily sales which are tracked in database
  percent=100*count_track/count.to_f
  
  #a complicated way to print the percent to one decimal place
  print percent.floor,"."+(percent-percent.floor).to_s[2]+"% of sales correspond to products in the product feed.\n"
  
  %x{echo 'set term png; set output "test.png"; set xlabel "Utility"; set ylabel "Sales"; plot "temp.txt" title "Utility vs Sales"' | gnuplot -persist}
  
  %x{rm temp.txt}
  
end


#returns an hash mapping product sku's to quantity purchased

def parse_data()
  x={}
  file = File.new("/rough_code/Products Report for BestBuy.ca Prod - Tue. 13 Sep. 2011.csv","r")
  
  while (line = file.gets)
    s="#{line}"
    if s =~/\d+\.,,[\d|A-Z]+,,/
      #print s.scan(/,[\d|A-Z]+,/)," ",s.scan(/,[\d|A-Z]+,/).length,"\n"
      y=s.scan(/,[\d|A-Z]+,/)
      
      #the line below is a little confusing
      #basically, y is an array containing some strings with useful information
      #I look for some substrings, they get put in arrays, I select first and only element
      
      x[y[0].scan(/[\d|A-Z]+/)[0]] = y[1].scan(/\d+/)[0].to_i
    end
  end
  return x
end  