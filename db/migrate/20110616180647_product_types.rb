class ProductTypes < ActiveRecord::Migration
  def self.up
    create_table :product_types do |t|
      t.string :name, :null=>false 
      t.string :layout, :default=>'assist'
      t.timestamps
    end

    add_index :product_types, :name, :unique => true
  end

  def self.down
    remove_index :product_types, :name
    drop_table :product_types
  end
end
