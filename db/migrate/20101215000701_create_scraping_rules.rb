# ScrapingRules is the table for general rules that apply to features.
# For individual sku corrections, look in scraping_corrections.
class CreateScrapingRules < ActiveRecord::Migration
  def self.up
    create_table :scraping_rules do |t|
      t.primary_key :id
      t.string :local_featurename
      t.string :remote_featurename
      t.text :regex
      t.string :product_type
      t.float :min
      t.float :max
      t.text :valid_inputs
    end
  end

  def self.down
    drop_table :scraping_rules
  end
end
