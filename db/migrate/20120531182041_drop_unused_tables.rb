class DropUnusedTables < ActiveRecord::Migration
  def up
    drop_table :users
    drop_table :urls
    drop_table :search_products
    drop_table :scraped_cameras
    drop_table :results_scraping_rules
    drop_table :results
    drop_table :product_types
    drop_table :keyword_searches
    drop_table :headings
    drop_table :features
    drop_table :category_id_product_type_maps
    drop_table :categorical_facet_values
    drop_table :candidates
  end

  def down
  end
end
