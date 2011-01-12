class CreateTextSpecs < ActiveRecord::Migration
  def self.up
    create_table :text_specs do |t|
      t.primary_key :id
      t.integer :product_id
      t.string :name
      t.text :value
      t.string :product_type

      t.timestamps
    end
    add_index :text_specs, :product_id
  end

  def self.down
    drop_table :text_specs
  end
end
