class CreateSearchProducts < ActiveRecord::Migration
  def self.up
    create_table :search_products do |t|
      t.integer :search_id
      t.integer :product_id
    end
    add_index :search_products, :search_id
  end

  def self.down
    drop_table :search_products
  end
end
