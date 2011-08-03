class ProductBundle < ActiveRecord::Migration
  def self.up
    create_table :product_bundles do |t|
      t.integer :bundle_id
      t.integer :product_id
      t.string :product_type
      t.timestamps
    end
  end

  def self.down
    drop_table :product_bundles
  end
end
