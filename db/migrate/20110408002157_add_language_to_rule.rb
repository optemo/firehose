class AddLanguageToRule < ActiveRecord::Migration
  def self.up
    add_column :scraping_rules, :french, :boolean, :default => false
  end

  def self.down
    remove_column :scraping_rules, :french
  end
end
