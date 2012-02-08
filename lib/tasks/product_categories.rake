desc ""
task :fill_categories => :environment do
  # starting at the root node of the API
  # for bestbuy, that's 'Departments'
  # for futureshop, that's 'Departments'?
  # starting at the root
  # do a modified preorder traversal (?)
  # set node.left to ++n;  for each child in order, call function with n -> increments n each time;
  # when the children of a node are done, set node.left to ++n;

  
  traverse({'20005'=>'Cameras & Camcorders'}, 0, 1)
  debugger
  # $english = false
  # traverse({'20005'=>'Departments'}, 0, 1)
  
  puts 'Done saving categories'
end

def traverse(root_node, i, level)
  # get the children of the node

  name = root_node.values.first
  catid = root_node.keys.first
  english_name = root_node.values.first
  french_name = BestBuyApi.get_category(catid, false)["name"]
  
  retailer = ENV["retailer"]
  prefix = retailer == 'bestbuy' ? 'B' : 'F'
  i = i + 1
  cat = ProductCategory.new(:product_type => prefix + catid, :feed_id => catid, :retailer => retailer, 
        :l_id => i, :level => level)
  # Store a translation in locale for catid -> name
  
  I18n.backend.store_translations(:en, cat.product_type => { "name" => english_name} )
  I18n.backend.store_translations(:fr, cat.product_type => { "name" => french_name} )
  #debugger
  
  children = BestBuyApi.get_subcategories(catid).values.first
  
  children.each do |child|
    traverse(child, i, level+1)
  end
  
  i = i + 1
  cat.r_id = i
  cat.save()
end

