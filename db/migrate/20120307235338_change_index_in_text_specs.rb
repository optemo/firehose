class ChangeIndexInTextSpecs < ActiveRecord::Migration
  def self.up
    remove_index :text_specs, [:product_id, :name]
    add_index :text_specs, [:product_id, :name], :unique=>false
  end

  def self.down
    remove_index :text_specs, [:product_id, :name]
    add_index :text_specs, [:product_id, :name], :unique=>true
  end
end
