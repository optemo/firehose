class AddIndexToFacets < ActiveRecord::Migration
  def self.up
    add_index :facets, :used_for
  end

  def self.down
    remove_index :facets, :used_for
  end
end
