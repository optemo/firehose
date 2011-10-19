


#This function reads in a list L of copurchases,
#computes top copurchased accessories for each camera & drive
#inserts into website

#It is found that the program spends almost 100 % of its time
#building a co-occurence hash, i.e. counting how many time pairs of products where bought together

#sorting the resulting hash & putting it on the web, as well as the initial file read, happen almost instantaneously.

#The time for this dominating step is

#    T=c * |L| * Avg_{l \in L} |l|^2

#where c is an unknown constant

#experimental estimates for c fall between

$c_min=0.0097
$c_max=0.0148

task :insert_accessories => :environment do
  
  print "\n"
  print "Reading in Copurchased Products..."
  l=read_list_from_file()
  
  start_time=Time.now
  
  print "Building Concurrence Hash..."
  c=Build_Concurrence_Hash(l)
  print "done.\n"
  
  print "Adding to online Database..."
  c.keys.each do |key|
    #print key,c[key],"\n"
    s=top_copurchases_string(key,2,c) #string of top 2 copurchase skus
    p=Product.find_by_sku(key)
    
    #check if product p has a "top_copurchases text spec already"
    #if it does, modify.  Otherwise create.
    t=p.text_specs.find_by_name("top_copurchases")
    #if t
    #  t.value=s
    #  t.save
    #else      
    #  t=TextSpec.new
    #  t.name="top_copurchases"
    #  t.value=s
    #  t.product_id=p.id
    #  t.product_type=p.product_type
    #  t.save 
    #end   
  end
  
  end_time=Time.now
  
  delta=time_gap(start_time,end_time)
  
  print "done.\n","Elapsed time = ",min_sec(delta),".\n"
  print "\n"
end  

#returns the distance in seconds between t2 and t1

#t1,t2 are output stings from ruby's "Time.now" function.
#this function assumes t1 & t2 are on the same day

def time_gap(t1,t2)

h1=t1.to_s[11..12].to_i #hour
m1=t1.to_s[14..15].to_i #minute
s1=t1.to_s[17..18].to_i #second

h2=t2.to_s[11..12].to_i #hour
m2=t2.to_s[14..15].to_i #minute
s2=t2.to_s[17..18].to_i #second

return 3600*(h2-h1)+60*(m2-m1)+(s2-s1)

end

def min_sec(t)
  return ((t/60).floor).to_s+" min "+((t%60).floor).to_s+" sec"
end


# Takes in a list l of sets of co-purchased products (in the form of product sku's)
# and outputs a hash c.  If i & j are product sku's, then

# c[i][j]=k         if i,j have been copurchased k times and

# c[i][j]=nil       if they have never been copurchased, or if the purchase is not relevant (see following paragraph) 

#The rows of c are cameras and drives, while the columns are camera and drive accessories.
#If a given row corresponds to a camera, only copurchases corresponding to camera accessories are kept track of
#So, if i is a camera sku and j a drive accessory sku, c[i][j] will be nil even if i&j have been copurchased

# NOTE:  if sku i does not appear anywhere in l, then calling c[i][j] will cause an error
#        however, if i appears while j doesn't, c[i][j] is just nil. 

# the hash will be sorted in descending order on output

#At the end, the hash produced is something like

#{1=>[[2, 3], [3, 1], [4, 1], [5, 1]], 
# 2=>[[1, 3], [3, 1], [4, 1], [5, 1]], 
# 3=>[[1, 1], [2, 1]], 
# 4=>[[2, 1], [1, 1]], 
# 5=>[[2, 1], [1, 1]]}

#this means product 1 was copurchased with product 2 three times, and products 3, 4 5 once, and so on.

#if you try to load skus which aren't in the database, they will not be added, and an error message will be displayed

def Build_Concurrence_Hash(l)
  c = Hash.new{|h,k| h[k] = []} #Initialize to empty array
  puts "Number of purchases #{l.length}"
  copurchases = 0
  l.each do |s|
    #<><><><>
    next if s.length < 2 #Only look at copurchases
    products = s.map do |sku|
      Product.find_by_sku_and_instock(sku,true) #check that a product with sku1 exists in the database
    end.compact
    next if products.length < 2 #Recheck after missing products
    products = products.select{|p| p.product_type == "camera_bestbuy" || p.product_type == "camera_accessory_bestbuy"}
    next if products.length < 2 #Recheck after missing products
    products.each do |p|
      if p.product_type == "camera_bestbuy"
        acc = products.reject{|i|i.sku == p.sku || i.product_type != "camera_accessory_bestbuy"}
        c[p.sku] << acc unless acc.empty?
      end
    end
    
    #we want rows of c to be cameras and drives, while columns are relavent accesories
    #if p1.product_type=="camera_bestbuy" #&& p2.product_type=="camera_accessory_bestbuy" #||       p1.cat_specs.select{|s| s.name=="category"}[0].value!="29583" && p2.cat_specs.select{|s| s.name=="category"}[0].value=="29583"
    # 
    #   #second line means that p1 is not a harddrive accessory but p2 is.  
    #   #instead of having a "drive_accessory_bestbuy" product type,
    #   #there is a product cat_spec with the name category that has the value 29583 if the product
    #   #is a drive accessory
    #   puts p1.sku
    #   c[sku1]={} if c[sku1]==nil
    #   if c[sku1][sku2]==nil
    #     c[sku1][sku2]=1
    #   else
    #     c[sku1][sku2]+=1
    #   end
    #end
    #<><><><>
  end

  #sorts hash by counts
  max_accessories = c.values.map(&:length).max
  puts "Number of products with copurchases: #{c.keys.count}, with max: #{max_accessories}"
  c.each_pair do |k,v|
    next unless v.length == max_accessories
    grouped = v.flatten.group_by(&:sku)
    grouped.each_pair{|k,v|grouped[k] = v.length}
    puts "Highest copurchases(#{k}) has #{grouped.length} accessories:"
    puts grouped
    break
  end

  ps = Product.instock.select{|p|c.has_key? p.sku}
  puts "Instock Cameras #{ps.length} / #{Product.instock.where(:product_type => "camera_bestbuy").count}"
  
  return c

end

# returns top k copurchases of product p.  Uses hash c from previous function
# returns result as a string
def top_copurchases_string(p,k,c)
    top=""
    for i in (0...[k,c[p].length].min) #it is possible there are less than k copurchased products
      top=top+c[p][i][0].to_s+" "
    end
    return top
end



#read from file the list of copurchases

def read_list_from_file()
  orders = Hash.new{|h,k| h[k] = []} #Initialize to empty array
  abort("No file provided (file=example.csv)") if !ENV.include?("file")
  file = File.new(ENV["file"],"r")
  file.gets #First line is heading, throw away
  count = 0
  file.each do |line|
    web_order, date, sku = line.split(',')
    orders[web_order] << sku.chomp
    count += 1
  end
  puts "Read input file: #{count} lines"
  file.close
  return orders.values
end
