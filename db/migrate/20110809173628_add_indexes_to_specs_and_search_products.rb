class AddIndexToSpecsAndSearchProducts < ActiveRecord::Migration
  def self.up
    add_index :bin_specs, [:name, :value]
    add_index :cat_specs, [:name]
    add_index :cont_specs, [:name, :value]
    add_index :search_products, [:product_id]
  end

  def self.down
    remove_index :bin_specs, [:name, :value]
    remove_index :cat_specs, [:name]
    remove_index :cont_specs, [:name, :value]
    remove_index :search_products, [:product_id]
  end
end
