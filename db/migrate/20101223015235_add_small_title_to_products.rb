class AddSmallTitleToProducts < ActiveRecord::Migration
  def self.up
    add_column :products, :small_title, :string
  end

  def self.down
    remove_column :products, :small_title
  end
end
