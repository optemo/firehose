# Scraped corrections is the table for individual corrections on a per-sku basis.
# General rules go in scraping_rules.
class CreateScrapingCorrections < ActiveRecord::Migration
  def self.up
    create_table :scraping_corrections do |t|
      t.primary_key :id
      t.string :sku
      t.string :product_type
      t.string :raw
      t.string :corrected
      t.string :feature
    end
  end

  def self.down
    drop_table :scraping_corrections
  end
end
