class CreateBinSpecs < ActiveRecord::Migration
  def self.up
    create_table :bin_specs do |t|
      t.primary_key :id
      t.integer :product_id
      t.string :name
      t.boolean :value
      t.string :product_type

      t.timestamps
    end
    add_index :bin_specs, :product_id
  end

  def self.down
    drop_table :bin_specs
  end
end
