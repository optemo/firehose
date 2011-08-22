class CreateDynamicFacets < ActiveRecord::Migration
  def self.up
    create_table :dynamic_facets do |t|
      t.references :facet, :null=>false
      t.string :category, :null=>false
    end

    add_index :dynamic_facets, [:facet_id, :category], :unique=>true
  end

  def self.down
    remove_index :dynamic_facets, [:facet_id, :category]
    drop_table :dynamic_facets
  end
end
