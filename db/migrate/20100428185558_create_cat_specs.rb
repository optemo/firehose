class CreateCatSpecs < ActiveRecord::Migration
  def self.up
    create_table :cat_specs do |t|
      t.primary_key :id
      t.integer :product_id
      t.string :name
      t.string :value
      t.string :product_type

      t.timestamps
    end
    add_index :cat_specs, :product_id
  end

  def self.down
    drop_table :cat_specs
  end
end
