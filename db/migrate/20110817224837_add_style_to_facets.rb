class AddStyleToFacets < ActiveRecord::Migration
  def self.up
    add_column :facets, :style, :string, :default=>''
  end

  def self.down
    remove_column :facets, :style
  end
end
