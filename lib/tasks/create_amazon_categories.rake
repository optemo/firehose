task :create_amazon_categories => :environment do
  retailer = 'A'
  root = 'ADepartments'
  children = ['Amovie_amazon', 'Atv_amazon', 'Acamera_amazon', 'Asoftware_amazon']
  
  id = 1
  
  cat = ProductCategory.find_or_initialize_by_product_type_and_feed_id(root, root)
  cat.update_attributes(retailer: retailer, l_id: id, level: 1)
  
  for child in children
    cat = ProductCategory.find_or_initialize_by_product_type_and_feed_id(child, child)
    cat.update_attributes(retailer: retailer, l_id: id += 1, r_id: id += 1, level: 2)
  end
  
  ProductCategory.find_by_product_type_and_feed_id(root, root).update_attributes(r_id: id += 1)
  
end