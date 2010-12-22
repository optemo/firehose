class SearchDataToSearches < ActiveRecord::Migration
  def self.up
    add_column :searches, :searchpids, :text
    add_column :searches, :searchterm, :string
  end

  def self.down
    remove_column :searches, :searchpids
    remove_column :searches, :searchterm
  end
end
