class CreateCategoricalFacetValues < ActiveRecord::Migration
  def self.up
    create_table :categorical_facet_values do |t|
      t.primary_key :id
      t.integer :facet_id
      t.string  :name
      t.float   :value
      t.timestamps
    end
    add_index :categorical_facet_values, :facet_id
  end

  def self.down
    remove_index :create_facet_values, :facet_id
    drop_table :categorical_facet_values
  end
end
