#Function adds total number of sales a products has, then writes them to cont specs table
#Going back 0 days returns 0 sales, 1 day returns only the previous days sales, 2 days the previous two days' sales...
def write_sale_in_time_frame (number_of_days)
  require 'date'
  missing_prods = []
  
  #add function to remove products that are not in the daily specs
  products = Product.find_all_by_instock(1)
  products.each do |product|
    sales = 0
    count = 0
    day_wanted = Date.today.prev_day
    
    for day in 1..number_of_days
      #Check in case the product order number does not exist in DailySpec for a particular day.
      if DailySpec.where(:date => day_wanted.strftime("%Y-%m-%d"), :sku => product.sku, :name => "orders").empty?
        puts "Product: #{product.sku} does not exist in the DailySpec table for the date #{day_wanted.to_s}"
        count += 1
      else
        sales += DailySpec.where(:date => day_wanted.strftime("%Y-%m-%d"), :sku => product.sku, :name => "orders").first.value_flt
        #DailySpec.find_all_by_date_and_sku_and_name(day_wanted.strftime("%Y-%m-%d"), product.sku, "orders").value_flt        
      end
      day_wanted = day_wanted.prev_day
    end
    
    #If the product already has an orders row, update this, otherwise make a new one
    if ContSpec.where(:product_id => product.id, :name => "orders", :product_type => product.product_type).empty?
      cont = ContSpec.new(:product_id => product.id, :name => "orders", :value => sales, :product_type => product.product_type) 
      cont.save
    else
      temp_cont = ContSpec.where(:product_id => product.id, :name => "orders", :product_type => product.product_type).first
      ContSpec.update(temp_cont.id, :value => sales)
    end
    
    #Stores the products that had no presence in DailySpec (check -> shouldn't normally happen))
    if count == number_of_days
      missing_prods.push(product.sku)
    end
  end
  
  p "Products missing completely from DailySpec table: "+missing_prods
end