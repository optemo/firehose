class AddActiveToFacets < ActiveRecord::Migration
  def self.up
    add_column :facets, :active, :boolean, :default=>true
  end

  def self.down
    remove_column :facets, :active
  end
end
