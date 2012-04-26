desc "Traverse the hierachy of categories from the API and store it in the database"
task :fill_categories => :environment do
  ['F','B'].each do |retailer|
    ENV["retailer"] = retailer
    ProductCategory.where(:retailer => retailer).delete_all
    traverse({'Departments'=>'Departments'}, 1, 1)
    p "Done saving categories for "+ ENV["retailer"]
  end
end

def traverse(root_node, i, level)
  # traverse the subtree of categories starting at root_node, mark nodes in the product category table,
  # and save both English and French translations 
  name = root_node.values.first
  catid = root_node.keys.first
  english_name = root_node.values.first
  
  retailer = ENV["retailer"]
  Session.product_type = retailer
  
  puts catid
  
  begin
    french_name = BestBuyApi.get_category(catid, false)["name"]
  rescue BestBuyApi::TimeoutError
    puts 'got timeout; waiting and trying again'
    puts catid
    sleep(60)
    retry
  end
  
  # These categories are left singular in the feed
  # Regex is used fit file encoding (could change it to UTF 8 (according to stackoverflow post) and use the string normally with 'e' accent aigu)
  if english_name == "Digital SLR" && /^Appareil photo reflex (?<need_accent_numerique>num.rique)$/ =~ french_name
    english_name = "Digital SLRs"
    french_name = "Appareils photo reflex #{need_accent_numerique}s"
  end
  
  prefix = retailer
  
  cat = ProductCategory.new(:product_type => prefix + catid, :feed_id => catid, :retailer => retailer, 
        :l_id => i, :level => level)
  
  i = i + 1
  
  I18n.backend.store_translations(:en, cat.product_type => { "name" => english_name} )
  I18n.backend.store_translations(:fr, cat.product_type => { "name" => french_name} )
    
  begin
    children = BestBuyApi.get_subcategories(catid).values.first
  rescue BestBuyApi::TimeoutError
    puts 'got timeout; waiting and trying again'
    sleep(60)
    retry
  end
  
  children.each do |child|
    i = traverse(child, i, level+1)
  end
  
  cat.r_id = i
  cat.save()
  
  i = i + 1
  return i
end

