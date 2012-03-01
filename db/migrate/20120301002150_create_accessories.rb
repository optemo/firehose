class CreateAccessories < ActiveRecord::Migration
  def change
    create_table :accessories do |t|
      t.integer :product_id
      t.integer :accessory_id
      t.integer :count

      t.timestamps
    end
  end
end
