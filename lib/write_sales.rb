#Function adds total number of sales a products has, then writes them to cont specs table
#Going back 0 days returns 0 sales, 1 day returns only the previous days sales, 2 days the previous two days' sales...
def write_sale_in_time_frame (number_of_days)
  require 'date'
  missing_prods = []
  
  products = Product.find_all_by_instock(1)
  products.each do |product|
    sales = 0
    count = 0
    ################# CHANGE THIS BACK TO THE LINE BELOW FOR NORMAL OPERATION (today line) ######################
    #day_wanted = Date.new(2012,2,9)
    day_wanted = Date.today.prev_day
  
    for day in 1..number_of_days
      #Check in case the product order number does not exist in DailySpec for a particular day.
      if DailySpec.where(:date => day_wanted.strftime("%Y-%m-%d"), :sku => product.sku, :name => "orders").empty?
        #for testing purposes: remove when done
        puts "Product: #{product.sku} does not exist in the DailySpec table for the date #{day_wanted.to_s}"
        count += 1
      else
        sales += DailySpec.where(:date => day_wanted.strftime("%Y-%m-%d"), :sku => product.sku, :name => "orders").first.value_flt
      end
      day_wanted = day_wanted.prev_day
    end
  
    #Stores the products that had no presence in DailySpec
    if count == number_of_days
      missing_prods.push(product.sku)
    end
  
    #Make a new orders row, unless the product already has one (update it then)
    if ContSpec.where(:product_id => product.id, :name => "orders", :product_type => product.product_type).empty?
      cont = ContSpec.new(:product_id => product.id, :name => "orders", :value => sales, :product_type => product.product_type) 
      cont.save
    else
      temp_cont = ContSpec.where(:product_id => product.id, :name => "orders", :product_type => product.product_type).first
      ContSpec.update(temp_cont.id, :value => sales)
    end
  end

  p "Products missing orders in DailySpec table: "+missing_prods.to_s
end