class CreateProductCategories < ActiveRecord::Migration
  def up  
    create_table :product_categories do |t|
      t.primary_key :id
      t.string :product_type
      t.string :feed_id
      t.string :retailer
      t.integer :l_id
      t.integer :r_id
      t.integer :level
    end
  end

  def down
    drop_table :product_categories
  end
  
end