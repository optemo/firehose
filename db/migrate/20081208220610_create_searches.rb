class CreateSearches < ActiveRecord::Migration
  def self.up
    create_table :searches do |t|
      t.primary_key :id
      t.integer :session_id
      t.integer :parent_id
      t.boolean :initial
      t.string :keyword_search
      t.integer :page
      t.string :groupby
      t.timestamps
    end
  end

  def self.down
    drop_table :searches
  end
end
