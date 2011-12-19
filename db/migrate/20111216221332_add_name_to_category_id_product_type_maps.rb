class AddNameToCategoryIdProductTypeMaps < ActiveRecord::Migration
  def change
    add_column :category_id_product_type_maps, :name, :string
  end
end
