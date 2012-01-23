class ChangeProductType < ActiveRecord::Migration
  def up
    # add column product_type_id
    add_column :bin_specs, :product_type_id, :integer
    BinSpec.where("product_type = 'camera_bestbuy'").update_all(:product_type_id => 2)
    BinSpec.where("product_type = 'tv_bestbuy'").update_all(:product_type_id => 4)
    BinSpec.where("product_type = 'drive_bestbuy'").update_all(:product_type_id => 6)
    # for each of product_type, fill with corresponding product_type_id
    # delete column product_type
    remove_column :bin_specs, :product_type
  end

  def down
    add_column  :bin_specs, :product_type, :string
    BinSpec.where("product_type_id = 2").update_all(:product_type => 'camera_bestbuy')
    BinSpec.where("product_type_id = 4").update_all(:product_type => 'tv_bestbuy')
    BinSpec.where("product_type_id = 6").update_all(:product_type => 'drive_bestbuy')
    remove_column :bin_specs, :product_type_id
    # add column product_type
    # for each of product_type_id, fill with corresponding product_type
    # delete column product_type_id
  end
end
