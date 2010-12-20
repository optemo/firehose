class CreateScrapingCorrections < ActiveRecord::Migration
  def self.up
    create_table :scraping_corrections do |t|
      t.primary_key :id
      t.string :product_id
      t.string :product_type
      t.string :raw
      t.string :corrected
      t.string :remote_featurename

      t.timestamps
    end
  end

  def self.down
    drop_table :scraping_corrections
  end
end
