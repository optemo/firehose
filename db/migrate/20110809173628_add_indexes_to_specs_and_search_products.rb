class AddIndexesToSpecsAndSearchProducts < ActiveRecord::Migration
  def self.up
    add_index :bin_specs, [:name]
    add_index :cat_specs, [:name]
    add_index :cont_specs, [:value]
    add_index :cont_specs, [:name, :product_id]
    add_index :search_products, [:product_id]
  end

  def self.down
    remove_index :bin_specs, [:name]
    remove_index :cat_specs, [:name]
    remove_index :cont_specs, [:name]
    remove_index :cont_specs, [:name, :product_id]
    remove_index :search_products, [:product_id]
  end
end
