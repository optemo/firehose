class AddParamsHashToSearches < ActiveRecord::Migration
  def up
    add_column :searches, :params_hash, :string
    add_index :searches, :params_hash
  end

  def down
    remove_index :searches, :params_hash  
    remove_column :searches, :params_hash
  end

end
