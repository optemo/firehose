class AddCorrectionsToCondidate < ActiveRecord::Migration
  def self.up
    add_column :candidates, :scraping_correction_id, :integer
  end

  def self.down
    remove_column :candidates, :scraping_correction_id
  end
end
