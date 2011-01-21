class CreateProductSiblings < ActiveRecord::Migration
  def self.up
     create_table :product_siblings do |t|
       t.primary_key :id
       t.integer :product_id
       t.integer :sibling_id
       t.string :name
       t.float :value
       t.string :product_type
    
       t.timestamps
     end
     add_index :product_siblings, :product_id
  end

  def self.down
    drop_table :product_siblings
  end
end
