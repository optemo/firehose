class AddActiveColumnToScrapingRules < ActiveRecord::Migration
  def self.up
    add_column :scraping_rules, :active, :boolean, :default => 1
  end

  def self.down
    remove_column :scraping_rules, :active
  end
end
