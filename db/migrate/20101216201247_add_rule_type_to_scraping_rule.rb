class AddRuleTypeToScrapingRule < ActiveRecord::Migration
  def self.up
    add_column :scraping_rules, :rule_type, :string    
  end

  def self.down
    remove_column :scraping_rules,:rule_type
  end
end
