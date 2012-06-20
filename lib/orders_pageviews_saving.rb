# Save online orders to either daily_specs or all_daily_specs (all_daily_specs can't use mass inserts)
# TODO: move the all_daily_specs specific code into another function / file, while modularizing the code

def save_online_orders(filename,date,daily_updates,table,retailer)
  puts "Saving #{retailer} online_orders for #{date}"
  
  orders_map = {} # map of sku => orders
  File.open(filename, 'r') do |f|
    f.each do |line|
      /\d+\.,,(?<sku>[^,]+),,(?<rev>"?\$\d+(,\d+)?"?),,,,[^,]+,,(?<orders>\d+)/ =~ line
      orders_map[sku] = orders if sku
    end
  end

  case table
  when /^[Dd]aily((Spec)|(_specs))/  # Save sales to daily_specs
    rows = []
    products = DailySpec.where("date = ? AND name = ? AND product_type REGEXP ?", date, 'instock', retailer).select("DISTINCT(sku),product_type")
    products.each do |prod|
      sku = prod.sku         
      product_type = prod.product_type
      orders_spec = orders_map[sku] # For sales of over 999 (comma messes things up)
      orders = (orders_spec.nil?) ? "0" : orders_spec.delete(',')
      rows.push(["cont",sku,"online_orders",orders,date,product_type])
    end
    columns = %W( spec_type sku name value_flt date product_type )
    DailySpec.import(columns,rows,:on_duplicate_key_update=>[:value_flt]) 
    
  when /^[Aa]ll((DailySpec)|(_daily_specs))/ # Get products from and save sales to all_daily_specs
    products = AllDailySpec.where(:date => date).select("DISTINCT(sku),product_type")
    products.each do |prod|
      sku = prod.sku
      product_type = prod.product_type
      orders_spec = orders_map[sku].try(:delete,',')
      orders = (orders_spec.nil?) ? "0" : orders_spec
      # write orders to online_orders for the date and the sku
      AllDailySpec.create(:spec_type => "cont", :sku => sku, :name => "online_orders", :value_flt => orders, :date => date, :product_type => product_type)
    end
  end
end

# Saves pageviews to table specified
def save_pageviews(filename,date,daily_updates,table,retailer)
  puts "Saving #{retailer} pageviews for #{date}"
  
  views_map = {} # map of sku => views
  File.open(filename, 'r') do |f|
    f.each do |line|
      /\d+\.,,(?<sku>[^,N]{8}),,"?(?<views>\d+(,\d+)*)"?.+/ =~ line
      views_map[sku] = views if sku
    end
  end

  case table
  when /^[Dd]aily((Spec)|(_specs))/  # Save sales to daily_specs
    rows = []
    # FIXME: this code is almost identical to the one for orders TODO: refactor the two together with pageviews / orders param
    products = DailySpec.where("date = ? AND name = ? AND product_type REGEXP ?", date, 'instock', retailer).select("DISTINCT(sku),product_type")
    products.each do |prod|
      sku = prod.sku
      product_type = prod.product_type
      views_spec = views_map[sku]
      views = (views_spec.nil?) ? "0" : views_spec.delete(',')  # the one difference is where this delete comma is done  
      rows.push(["cont",sku,"pageviews",views,date,product_type])
    end
    columns = %W( spec_type sku name value_flt date product_type )
    DailySpec.import(columns,rows,:on_duplicate_key_update=>[:value_flt])
    
  when /^[Aa]ll((DailySpec)|(_daily_specs))/ # Get products from and save pageviews to all_daily_specs
    products = AllDailySpec.where(:date => date).select("DISTINCT(sku),product_type")
    products.each do |prod|
      sku = prod.sku
      product_type = prod.product_type
      views_spec = views_map[sku]
      views = (views_spec.nil?) ? "0" : views_spec
      # write orders to online_orders for the date and the sku
      AllDailySpec.create(:spec_type => "cont", :sku => sku, :name => "pageviews", :value_flt => views, :date => date, :product_type => product_type)
    end
  end
end