class DropResultsScrapingRules < ActiveRecord::Migration
  def self.up
    drop_table('results_scraping_rules')
  end

  def self.down
  end
end
