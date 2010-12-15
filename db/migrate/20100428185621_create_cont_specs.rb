class CreateContSpecs < ActiveRecord::Migration
  def self.up
    create_table :cont_specs do |t|
      t.primary_key :id
      t.integer :product_id
      t.string :name
      t.float :value
      t.string :product_type

      t.timestamps
    end
    add_index :cont_specs, :product_id
  end

  def self.down
    drop_table :cont_specs
  end
end
