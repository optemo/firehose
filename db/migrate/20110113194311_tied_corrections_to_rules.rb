class TiedCorrectionsToRules < ActiveRecord::Migration
  def self.up
    remove_column :scraping_corrections, :remote_featurename
    add_column :scraping_corrections, :scraping_rule_id, :integer
  end

  def self.down
    add_column :scraping_corrections, :remote_featurename, :string
    remove_column :scraping_corrections, :scraping_rule_id
  end
end
