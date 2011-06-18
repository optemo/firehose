class ProductTypeUrls < ActiveRecord::Migration
  def self.up
    create_table :product_type_urls do |t|
      t.references :product_type, :null => false
      t.string :url, :null => false
      t.integer :port, :default => 80
      t.integer :weight, :default => 12
      t.timestamps
    end
    add_index :product_type_urls, [:url, :port], :unique=>true
    ProductType.find_each do |t|
      if t.name == 'camera_bestbuy'
        ProductTypeUrl.create :product_type => t, :url => 'firehose', :port => 80, :weight => 12
        ProductTypeUrl.create :product_type => t, :url => 'localhost', :port => 80, :weight => 12
        ProductTypeUrl.create :product_type => t, :url => 'bestbuy', :port => 80, :weight => 12
        ProductTypeUrl.create :product_type => t, :url => 'ilovecameras', :port => 80, :weight => 12
        ProductTypeUrl.create :product_type => t, :url => 'ilovecameras.optemo.com', :port => 80, :weight => 12
      end

      if t.name == 'tv_bestbuy'
        ProductTypeUrl.create :product_type => t, :url => 'besttv', :port => 80, :weight => 12
      end

      if t.name == 'drive_bestbuy'
        ProductTypeUrl.create :product_type => t, :url => 'bestdrive', :port => 80, :weight => 12
      end
    end

  end

  def self.down
    drop_table :product_type_urls
  end
end
