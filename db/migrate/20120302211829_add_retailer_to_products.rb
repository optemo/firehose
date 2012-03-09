class AddRetailerToProducts < ActiveRecord::Migration
  def change
    remove_column :products, :small_title
    add_column :products, :retailer, :string
  end
end
