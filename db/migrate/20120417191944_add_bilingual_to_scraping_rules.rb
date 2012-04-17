class AddBilingualToScrapingRules < ActiveRecord::Migration
  def change
    add_column :scraping_rules, :bilingual, :boolean, :default=>false
  end
end