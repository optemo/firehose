class AddIndexToProductBundles < ActiveRecord::Migration
  def self.up
    add_index :product_bundles, [:bundle_id], :unique=>true
  end

  def self.down
    remove_index :product_bundles, [:bundle_id], :unique=>true
  end
end
