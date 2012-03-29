# Save online orders to either daily_specs or all_daily_specs (all_daily_specs can't use mass inserts)
def save_online_orders(filename,date,daily_updates,table,retailer)
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
    if daily_updates  # Get instock products from non-updated products table
      products = Product.where(:instock => 1, :retailer => retailer)
      products.each do |prod|
        sku = prod.sku
        product_type = CatSpec.where(:product_id => prod.id, :name => 'product_type').first.try(:value)
        orders_spec = orders_map[sku].try(:delete,',') # For sales of over 999 (comma messes things up)
        orders = (orders_spec.nil?) ? "0" : orders_spec
        rows.push(["cont",sku,"online_orders",orders,date,product_type])
      end
    else  # Get instock products from daily_specs
      products = DailySpec.where("date = ? AND product_type REGEXP ?",date,retailer).select("DISTINCT(sku),product_type")
      products.each do |prod|
        sku = prod.sku         
        product_type = prod.product_type
        orders_spec = orders_map[sku].try(:delete,',')
        orders = (orders_spec.nil?) ? "0" : orders_spec
        rows.push(["cont",sku,"online_orders",orders,date,product_type])
      end
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

# Saves pageviews to daily_specs
def save_pageviews(filename,date,daily_updates,retailer)
  views_map = {} # map of sku => views

  File.open(filename, 'r') do |f|
    f.each do |line|
      /\d+\.,,(?<sku>[^,N]{8}),,"?(?<views>\d+(,\d+)*)"?.+/ =~ line
      views_map[sku] = views if sku
    end
  end

  rows = []
  if daily_updates # Get products from non updated products table (only instock from retailer given)
    products = Product.where(:instock => 1, :retailer => retailer)
    products.each do |prod|
      sku = prod.sku         
      product_type = CatSpec.where(:name => "product_type", :product_id => prod.id).first.try(:value)
      views_spec = views_map[sku]
      views = (views_spec.nil?) ? "0" : views_spec.delete(',')
      rows.push(["cont",sku,"pageviews",views,date,product_type])
    end
  else # Get products from daily_spec 
    products = DailySpec.where(:name => "instock")
    products.each do |prod|
      sku = prod.sku         
      product_type = prod.product_type
      views_spec = views_map[sku]
      views = (views_spec.nil?) ? "0" : views_spec.delete(',')
      rows.push(["cont",sku,"pageviews",views,date,product_type])
    end
  end
  columns = %W( spec_type sku name value_flt date product_type )
  DailySpec.import(columns,rows,:on_duplicate_key_update=>[:value_flt])
end