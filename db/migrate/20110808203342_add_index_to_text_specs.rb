class AddIndexToTextSpecs < ActiveRecord::Migration
  def self.up
    remove_index :text_specs, [:product_id]
    add_index :text_specs, [:product_id, :name], :unique=>true
  end

  def self.down
    remove_index :text_specs, [:product_id, :name], :unique=>true
    add_index :text_specs, [:product_id]
  end
end
