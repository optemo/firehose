class ProductTypeFeatures < ActiveRecord::Migration
  def self.up
    create_table :product_type_features do |t|
      t.references :product_type_heading, :null => false
      t.string :name, :null => false
      t.string :feature_type, {:null => false, :default => 'Categorical'}
      t.string :used_for, :default => 'show'
      t.boolean :prefdir, :default => true
      t.integer :min, :default => 0
      t.integer :max, :default => 0
      t.integer :utility, :default => 1
      t.integer :cluster, :default => 1
      t.string :prefered
      t.timestamps
    end

    add_index :product_type_features, [:product_type_heading_id, :name], :unique => true

    ProductTypeHeading.find_each do |h|
      if h.product_type.name == 'camera_bestbuy'
        if h.name == 'General'
          ProductTypeFeature.create :product_type_heading => h, :name => 'saleprice', :feature_type => 'Continuous',
          :used_for => 'filter, cluster, show', :prefdir => false, :min => 1, :max => 10000, :utility => 5, :cluster => 5
          ProductTypeFeature.create :product_type_heading => h, :name => 'maxresolution', :feature_type => 'Continuous',
          :used_for => 'desc, filter, cluster, show', :utility => 5, :cluster => 5
          ProductTypeFeature.create :product_type_heading => h, :name => 'screensize', :feature_type => 'Continuous',
          :used_for => 'desc, filter, show'
          ProductTypeFeature.create :product_type_heading => h, :name => 'opticalzoom', :feature_type => 'Continuous',
          :used_for => 'desc, filter, cluster, show', :utility => 5, :cluster => 5
          ProductTypeFeature.create :product_type_heading => h, :name => 'fblike', :feature_type => 'Continuous',
          :used_for => 'desc, filter, show', :utility => 5
          ProductTypeFeature.create :product_type_heading => h, :name => 'brand', :feature_type => 'Categorical',
          :used_for => 'show, filter, cluster', :utility => 5, :prefered => 'Canon, Sony, Nikon'
          ProductTypeFeature.create :product_type_heading => h, :name => 'color', :feature_type => 'Categorical',
          :used_for => 'filter, show'
          ProductTypeFeature.create :product_type_heading => h, :name => 'customerRating', :feature_type => 'Continuous',
          :used_for => 'show'
        end

        if h.name == 'Status'
          ProductTypeFeature.create :product_type_heading => h, :name => 'onsale', :feature_type => 'Binary',
          :used_for => 'filter', :utility => 10, :prefered => true
          ProductTypeFeature.create :product_type_heading => h, :name => 'isClearance', :feature_type => 'Binary',
          :used_for => 'filter'
          ProductTypeFeature.create :product_type_heading => h, :name => 'isOnlineOnly', :feature_type => 'Binary',
          :used_for => 'filter'
          ProductTypeFeature.create :product_type_heading => h, :name => 'toprated', :feature_type => 'Binary',
          :used_for => 'filter'
        end

        if h.name == 'Video Resolution'
          ProductTypeFeature.create :product_type_heading => h, :name => 'videoresolution720', :feature_type => 'Binary',
          :used_for => 'filter'
          ProductTypeFeature.create :product_type_heading => h, :name => 'videoresolution1080', :feature_type => 'Binary',
          :used_for => 'filter'
        end

        if h.name == 'New Technology'
          ProductTypeFeature.create :product_type_heading => h, :name => 'hdmi', :feature_type => 'Binary',
          :used_for => 'filter'
          ProductTypeFeature.create :product_type_heading => h, :name => 'touchscreen', :feature_type => 'Binary',
          :used_for => 'filter'
          ProductTypeFeature.create :product_type_heading => h, :name => 'imagestabilization', :feature_type => 'Binary',
          :used_for => 'filter'
          ProductTypeFeature.create :product_type_heading => h, :name => 'waterproof', :feature_type => 'Binary',
          :used_for => 'show, filter'
          ProductTypeFeature.create :product_type_heading => h, :name => 'oled', :feature_type => 'Binary',
          :used_for => 'filter'
          ProductTypeFeature.create :product_type_heading => h, :name => 'gps', :feature_type => 'Binary',
          :used_for => 'show, filter'
          ProductTypeFeature.create :product_type_heading => h, :name => 'projector', :feature_type => 'Binary',
          :used_for => 'filter'
          ProductTypeFeature.create :product_type_heading => h, :name => '3d', :feature_type => 'Binary',
          :used_for => 'show, filter'
          ProductTypeFeature.create :product_type_heading => h, :name => 'sweeppanorama', :feature_type => 'Binary',
          :used_for => 'show, filter'
          ProductTypeFeature.create :product_type_heading => h, :name => 'frontlcd', :feature_type => 'Binary',
          :used_for => 'show, filter'
      
        end
      end

      if h.product_type.name == 'tv_bestbuy'
        if h.name = 'General'
          ProductTypeFeature.create :product_type_heading => h, :name => 'price', :feature_type => 'Continuous',
          :used_for => 'filter, cluster, show', :prefdir => false, :min => 1, :max => 10000
          ProductTypeFeature.create :product_type_heading => h, :name => 'maxresolution', :feature_type => 'Continuous',
          :used_for => 'desc, filter, cluster, show'
          ProductTypeFeature.create :product_type_heading => h, :name => 'screensize', :feature_type => 'Continuous', 
          :used_for => 'desc, filter, cluster, show'
          ProductTypeFeature.create :product_type_heading => h, :name => 'power', :feature_type => 'Continuous',
          :used_for => 'desc, filter, cluster, show'
          ProductTypeFeature.create :product_type_heading => h, :name => 'brand', :feature_type => 'Categorical',
          :used_for => 'filter, show'
          ProductTypeFeature.create :product_type_heading => h, :name => 'displaytech', :feature_type => 'Categorical',
          :used_for => 'filter, show'
        end
      end

      if h.product_type.name == 'drive_bestbuy'
        if h.name = 'General'
          ProductTypeFeature.create :product_type_heading => h, :name => 'price', :feature_type => 'Continuous',
          :used_for => 'filter, cluster, show', :prefdir => false, :min => 1, :max => 10000
          ProductTypeFeature.create :product_type_heading => h, :name => 'brand', :feature_type => 'Categorical',
          :used_for => 'show, filter, cluster', :utility => 5
          ProductTypeFeature.create :product_type_heading => h, :name => 'customerRating', :feature_type => 'Continuous',
          :used_for => 'show'
          ProductTypeFeature.create :product_type_heading => h, :name => 'includeInBox', :feature_type => 'Categorical',
          :used_for => 'show'
          ProductTypeFeature.create :product_type_heading => h, :name => 'interface', :feature_type => 'Categorical',
          :used_for => 'show, filter, cluster'
          ProductTypeFeature.create :product_type_heading => h, :name => 'dimensions', :feature_type => 'Categorical',
          :used_for => 'show'
          ProductTypeFeature.create :product_type_heading => h, :name => 'pc', :feature_type => 'Categorical',
          :used_for => 'show'
          ProductTypeFeature.create :product_type_heading => h, :name => 'mac', :feature_type => 'Categorical',
          :used_for => 'show'
          ProductTypeFeature.create :product_type_heading => h, :name => 'weight', :feature_type => 'Categorical',
          :used_for => 'show'
          ProductTypeFeature.create :product_type_heading => h, :name => 'softwareIncluded', :feature_type => 'Categorical',
          :used_for => 'show'
          ProductTypeFeature.create :product_type_heading => h, :name => 'systemRequirements', :feature_type => 'Categorical',
          :used_for => 'show'
          ProductTypeFeature.create :product_type_heading => h, :name => 'maximumDataTransferRate', :feature_type => 'Categorical',
          :used_for => 'show'
        end
        if h.name == 'USB Flash Drives'
          ProductTypeFeature.create :product_type_heading => h, :name => 'capacity', :feature_type => 'Categorical',
          :used_for => 'show'
          ProductTypeFeature.create :product_type_heading => h, :name => 'isReadyBoostCompliant', :feature_type => 'Categorical',
          :used_for => 'show'
          ProductTypeFeature.create :product_type_heading => h, :name => 'isSoftwareIncluded', :feature_type => 'Categorical',
          :used_for => 'show'
          ProductTypeFeature.create :product_type_heading => h, :name => 'typeOfMedia', :feature_type => 'Categorical',
          :used_for => 'show'
        end
        if h.name == 'External/Internal Hard Drives, Solid State Drives, Storage Accessories'
          ProductTypeFeature.create :product_type_heading => h, :name => 'overageSeekTime', :feature_type => 'Categorical',
          :used_for => 'show'
          ProductTypeFeature.create :product_type_heading => h, :name => 'dataBuffer', :feature_type => 'Categorical',
          :used_for => 'show'
          ProductTypeFeature.create :product_type_heading => h, :name => 'rotaionsPerMinute', :feature_type => 'Categorical',
          :used_for => 'show'
          ProductTypeFeature.create :product_type_heading => h, :name => 'storageCapacity', :feature_type => 'Categorical',
          :used_for => 'show'
        end
        if h.name == 'DVD & CD Drives'
          ProductTypeFeature.create :product_type_heading => h, :name => 'cdReadSpeed', :feature_type => 'Categorical',
          :used_for => 'show'
          ProductTypeFeature.create :product_type_heading => h, :name => 'cdRewriteSpeed', :feature_type => 'Categorical',
          :used_for => 'show'
          ProductTypeFeature.create :product_type_heading => h, :name => 'cdWriteSpeed', :feature_type => 'Categorical',
          :used_for => 'show'
          ProductTypeFeature.create :product_type_heading => h, :name => 'dvdReadSpeed', :feature_type => 'Categorical',
          :used_for => 'show'
          ProductTypeFeature.create :product_type_heading => h, :name => 'dvdRewriteSpeed', :feature_type => 'Categorical',
          :used_for => 'show'
          ProductTypeFeature.create :product_type_heading => h, :name => 'dvdWriteSpeed', :feature_type => 'Categorical',
          :used_for => 'show'
          ProductTypeFeature.create :product_type_heading => h, :name => 'dataAccessTime', :feature_type => 'Categorical',
          :used_for => 'show'
          ProductTypeFeature.create :product_type_heading => h, :name => 'internal', :feature_type => 'Categorical',
          :used_for => 'show'
          ProductTypeFeature.create :product_type_heading => h, :name => 'external', :feature_type => 'Categorical',
          :used_for => 'show'
        end
      end


    end

  end


  def self.down
    remove_index :product_type_features, [:product_type_heading_id, :name]
    drop_table :product_type_features
  end
end
