class AddParamsToSearches < ActiveRecord::Migration
  def up
    add_column :searches, :params_list, :text
  end

  def down
    remove_column :searches, :params_list
  end

end
