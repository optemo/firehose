class MakeCorrectionsFieldText < ActiveRecord::Migration
  def self.up
    change_column :scraping_corrections, :corrected, :text
  end

  def self.down
    change_column :scraping_corrections, :corrected, :string
  end
end
