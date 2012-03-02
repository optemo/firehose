class CategoryIdProductTypeMaps < ActiveRecord::Migration
  def self.up
    remove_column :category_id_product_type_maps, :product_type
    add_column :category_id_product_type_maps, :product_type_id, :integer
  end

  def self.down
    remove_column :category_id_product_type_maps, :product_type_id
    add_column :category_id_product_type_maps, :product_type, :string
  end
end
