class RecreateKeywordSearches < ActiveRecord::Migration
  def self.up
    create_table :keyword_searches do |t|
      t.primary_key :id
      t.string :query
      t.integer :count

      t.timestamps
    end
    add_index :keyword_searches, :query
  end

  def self.down
    drop_table :keyword_searches
  end
end
