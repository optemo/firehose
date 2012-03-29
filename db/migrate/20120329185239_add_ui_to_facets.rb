class AddUiToFacets < ActiveRecord::Migration
  def change
    add_column :facets, :ui, :string
  end
end
