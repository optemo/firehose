class CreateScrapers < ActiveRecord::Migration
  def self.up
    create_table :scrapers do |t|

      t.timestamps
    end
  end

  def self.down
    drop_table :scrapers
  end
end
