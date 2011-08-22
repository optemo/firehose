class CreateFacets < ActiveRecord::Migration
  def self.up
    create_table :facets do |t|
      t.references :product_type, :null=>false
      t.string :name, :null=>false
      t.string :feature_type, :null=>false, :default=>'Categorical'
      t.string :used_for, :default=>'show'
      t.integer :value
    end

    add_index :facets, :product_type_id

  end

  def self.down
    remove_index :facets, :product_type_id
    drop_table :facets
  end
end
