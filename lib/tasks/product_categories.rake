desc "Traverse the hierachy of categories from the API and store it in the database"
task :fill_categories => :environment do  
  traverse({'Departments'=>'Departments'}, 1, 1)
  puts 'Done saving categories!'
end

def traverse(root_node, i, level)
  # traverse the subtree of categories starting at root_node, mark nodes in the product category table,
  # and save both English and French translations 

  name = root_node.values.first
  catid = root_node.keys.first
  english_name = root_node.values.first
  french_name = BestBuyApi.get_category(catid, false)["name"]
  
  retailer = ENV["retailer"]
  prefix = retailer == 'bestbuy' ? 'B' : 'F'
  
  cat = ProductCategory.new(:product_type => prefix + catid, :feed_id => catid, :retailer => retailer, 
        :l_id => i, :level => level)
  
  i = i + 1
  
  I18n.backend.store_translations(:en, cat.product_type => { "name" => english_name} )
  I18n.backend.store_translations(:fr, cat.product_type => { "name" => french_name} )
  
  begin
    children = BestBuyApi.get_subcategories(catid).values.first
  rescue BestBuyApi::RequestError
    puts catid
    puts 'got timeout; waiting and trying again'
    sleep(60)
    children = BestBuyApi.get_subcategories(catid).values.first
  end
  
  children.each do |child|
    i = traverse(child, i, level+1)
  end
  
  cat.r_id = i
  cat.save()
  
  i = i + 1
  return i
end

