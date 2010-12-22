class AddSortbyToSearch < ActiveRecord::Migration
  def self.up
    add_column :searches, :sortby, :string
  end

  def self.down
    remove_column :searches, :sortby
  end
end
