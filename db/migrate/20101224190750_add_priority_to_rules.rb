class AddPriorityToRules < ActiveRecord::Migration
  def self.up
    add_column :scraping_rules, :priority, :integer, :default => 0
  end

  def self.down
    remove_column :scraping_rules, :priority
  end
end
