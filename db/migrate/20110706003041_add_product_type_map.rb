class AddProductTypeMap < ActiveRecord::Migration
  def self.up
    create_table :category_id_product_type_maps do |t|
      t.string :product_type
      t.integer :category_id
      t.timestamps
    end
    add_index :category_id_product_type_maps, :category_id
  end

  def self.down
    drop_table :category_id_product_type_maps
  end
end
