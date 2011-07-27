class AddHasProductsToFeatures < ActiveRecord::Migration
  def self.up
    add_column :features, :has_products, :boolean, :default => 1
  end

  def self.down
    remove_column :features, :has_products
  end
end
