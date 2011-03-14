class AddModifiedColumnToSpecs < ActiveRecord::Migration
  def self.up
    add_column 'cont_specs', 'modified', :boolean
    add_column 'cat_specs', 'modified', :boolean
    add_column 'bin_specs', 'modified', :boolean
    add_column 'text_specs', 'modified', :boolean
  end

  def self.down
    remove_column 'cont_specs', 'modified'
    remove_column 'cat_specs', 'modified'
    remove_column 'bin_specs', 'modified'
    remove_column 'text_specs', 'modified'
  end
end
