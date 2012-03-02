class Urls < ActiveRecord::Migration
  def self.up
    create_table :urls do |t|
      t.references :product_type, :null => false
      t.string :url, :null => false
      t.integer :port, :default => 80
      t.integer :piwik_id, :default => 12
      t.timestamps
    end
    add_index :urls, [:url, :port], :unique=>true
  end

  def self.down
    remove_index :urls, [:url, :port]
    drop_table :urls
  end
end
