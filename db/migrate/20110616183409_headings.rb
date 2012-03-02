class Headings < ActiveRecord::Migration
  def self.up
    create_table :headings do |t|
      t.references :product_type, :null => false
      t.string :name, :null => false
      t.integer :show_order, :default => 9999
      t.timestamps
    end
    add_index :headings, [:product_type_id, :name], :unique => true
  end



  def self.down
    remove_index :headings, [:product_type_id, :name]
    drop_table :headings
  end
end
