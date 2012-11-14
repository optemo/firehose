task :prune_hierarchy => :environment do
  # keep leaf categories currently found in cat specs and their ancestors
  good_cats = ProductCategory.find_by_sql("SELECT DISTINCT value  FROM `cat_specs` WHERE `name` LIKE 'product_type' AND `value` LIKE '%B%'").map(&:value)
  categories_to_keep = Set.new
  categories_to_keep.merge(good_cats)
  good_cats.each { |leaf| categories_to_keep.merge(ProductCategory.get_ancestors(leaf)) }
  
  # delete rest of (BestBuy) categories from solr index, then from database
  bad_cats = ProductCategory.select { |pc| pc.retailer == 'B' && !categories_to_keep.include?(pc.product_type) }
  Sunspot.remove(bad_cats)
  Sunspot.commit
  bad_cats.map(&:destroy)
end
