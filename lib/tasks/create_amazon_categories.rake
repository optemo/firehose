task :create_amazon_categories => :environment do
  retailer = 'A'
  root = {'ADepartments' => 'Amazon Products'}
  children = {'Amovie_amazon' => 'Movies', 'Atv_amazon' => 'TVs', 'Acamera_amazon' => 'Cameras', 'Asoftware_amazon' => 'Software' }
    
  id = 1
  
  cat = ProductCategory.find_or_initialize_by_product_type_and_feed_id(root.keys.first, root.keys.first)
  cat.update_attributes(retailer: retailer, l_id: id, level: 1)
  
  children.each_pair do |type, name|
    cat = ProductCategory.find_or_initialize_by_product_type_and_feed_id(type, type)
    cat.update_attributes(retailer: retailer, l_id: id += 1, r_id: id += 1, level: 2)    
    I18n.backend.store_translations('en', type => {'name' => name})
  end
  root.each_pair do |type, name|
    ProductCategory.find_by_product_type_and_feed_id(type, type).update_attributes(r_id: id += 1)
    I18n.backend.store_translations('en', type => {'name' => name})
  end
  
end