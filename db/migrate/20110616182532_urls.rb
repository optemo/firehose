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
    ProductType.find_each do |t|
      if t.name == 'camera_bestbuy'
        Url.create :product_type => t, :url => 'firehose', :port => 80, :piwik_id => 12
        Url.create :product_type => t, :url => 'localhost', :port => 80, :piwik_id => 12
        Url.create :product_type => t, :url => 'bestbuy', :port => 80, :piwik_id => 12
        Url.create :product_type => t, :url => 'ilovecameras', :port => 80, :piwik_id => 12
        Url.create :product_type => t, :url => 'ilovecameras.optemo.com', :port => 80, :piwik_id => 12
      end

      if t.name == 'tv_bestbuy'
        Url.create :product_type => t, :url => 'besttv', :port => 80, :piwik_id => 12
      end

      if t.name == 'drive_bestbuy'
        Url.create :product_type => t, :url => 'bestdrive', :port => 80, :piwik_id => 12
      end
    end
-
  end

  def self.down
    remove_index :urls, [:url, :port]
    drop_table :urls
  end
end
