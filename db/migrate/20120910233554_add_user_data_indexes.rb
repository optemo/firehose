class AddUserDataIndexes < ActiveRecord::Migration
  def change
    add_index :userdatacats, :search_id
    add_index :userdatabins, :search_id
    add_index :userdataconts, :search_id
  end
end
