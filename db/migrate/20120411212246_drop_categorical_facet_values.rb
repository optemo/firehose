class DropCategoricalFacetValues < ActiveRecord::Migration
  def up
    drop_table :categorical_facet_values
  end
end
