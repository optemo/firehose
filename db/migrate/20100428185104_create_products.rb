class CreateProducts < ActiveRecord::Migration
  def self.up
    create_table :products do |t|
      t.primary_key :id
      t.string :sku
      t.string :product_type
      t.string :title
      t.string :model
      t.string :mpn
      t.boolean :instock
      t.string :imgsurl
      t.string :imgmurl
      t.string :imglurl

      t.timestamps
    end
  end

  def self.down
    drop_table :products
  end
end
