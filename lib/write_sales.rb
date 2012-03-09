#Function adds total number of sales a products has, then writes them to cont specs table
#Going back 0 days returns 0 sales, 1 day returns only the previous days sales, 2 days the previous two days' sales...
def write_sale_in_time_frame (number_of_days)
  require 'date' 
  
  ########## CHANGE THIS BACK TO THE LINE BELOW FOR NORMAL OPERATION (today line altered to look like current) ##########
  #date_range = (Date.new(2012,2,10)-number_of_days+1)..Date.new(2012,2,10)
  yesterday = Date.today.prev_day
  date_range = (yesterday-number_of_days+1)..yesterday

  before = Time.now
  products = Product.find_all_by_instock(1)
  products.each do |product|

    specs = DailySpec.where(:sku => product.sku, :name => "orders", :date=> date_range)
    unless specs.empty?
      sales = 0
      days_instock = 0
      date_range.each do |day|
        prod = specs.select{|f| f.date == day}.first
        #Check in case the product order number does not exist in DailySpec for a particular day.
        if prod
          sales += prod.value_flt
          days_instock +=1
        end
      end
      
      if days_instock == 0
        avg_sales = 0
      else
        avg_sales = sales/days_instock
      end
      
      #Make a new orders row, unless the product already has one (update it then)
      cont_spec = ContSpec.find_by_product_id_and_name(product.id, "orders")
      unless cont_spec.nil?
        ContSpec.update(cont_spec.id, :value => avg_sales)
      else
        cont = ContSpec.create(:product_id => product.id, :name => "orders", :value => avg_sales, :product_type => product.product_type) 
      end
    end
  end 
  after = Time.now
  p "Time taken (s): "+(after-before).to_s
end