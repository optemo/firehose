class ChangeUrLsIndex < ActiveRecord::Migration
  def self.up  
    remove_index :urls, [:url, :port]
    add_index :urls, [:product_type_id, :url, :port], :unique=>true
  end

  def self.down
    remove_index :urls, [:product_type_id, :url, :port], :unique=>true
    add_index :urls, [:url, :port]
  end
end
