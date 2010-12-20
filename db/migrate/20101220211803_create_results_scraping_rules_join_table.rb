class CreateResultsScrapingRulesJoinTable < ActiveRecord::Migration
  def self.up
    create_table :results_scraping_rules, :id => false do |t|
      t.integer :result_id
      t.integer :scraping_rule_id
    end
  end

  def self.down
    drop_table :results_scraping_rules
  end
end
