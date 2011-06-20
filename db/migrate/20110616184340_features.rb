class Features < ActiveRecord::Migration
  def self.up
    create_table :features do |t|
      t.references :heading, :null => false
      t.string :name, :null => false
      t.string :feature_type, {:null => false, :default => 'Categorical'}
      t.string :used_for, :default => 'show'
      t.boolean :larger_is_better, :default => true
      t.integer :min, :default => 0
      t.integer :max, :default => 0
      t.integer :utility_weight, :default => 1
      t.integer :cluster_weight, :default => 1
      t.string :prefered
      t.timestamps
    end

    add_index :features, [:heading_id, :name], :unique => true

    Heading.find_each do |h|
      if h.product_type.name == 'camera_bestbuy'
        if h.name == 'General'
          Feature.create :heading => h, :name => 'saleprice', :feature_type => 'Continuous',
          :used_for => 'filter, cluster, show, sortby', :larger_is_better => false, :min => 1, :max => 10000, :utility_weight => 5, :cluster_weight => 5
          Feature.create :heading => h, :name => 'maxresolution', :feature_type => 'Continuous',
          :used_for => 'desc, filter, cluster, show, sortby', :utility_weight => 5, :cluster_weight => 5
          Feature.create :heading => h, :name => 'screensize', :feature_type => 'Continuous',
          :used_for => 'desc, filter, show'
          Feature.create :heading => h, :name => 'opticalzoom', :feature_type => 'Continuous',
          :used_for => 'desc, filter, cluster, show, sortby', :utility_weight => 5, :cluster_weight => 5
          Feature.create :heading => h, :name => 'fblike', :feature_type => 'Continuous',
          :used_for => 'sortby', :utility_weight => 5
          Feature.create :heading => h, :name => 'brand', :feature_type => 'Categorical',
          :used_for => 'show, filter, cluster', :utility_weight => 5, :prefered => 'Canon, Sony, Nikon'
          Feature.create :heading => h, :name => 'color', :feature_type => 'Categorical',
          :used_for => 'filter, show'
          Feature.create :heading => h, :name => 'customerRating', :feature_type => 'Continuous',
          :used_for => 'show'
        end

        if h.name == 'Status'
          Feature.create :heading => h, :name => 'onsale', :feature_type => 'Binary',
          :used_for => 'filter', :utility_weight => 10, :prefered => true
          Feature.create :heading => h, :name => 'isClearance', :feature_type => 'Binary',
          :used_for => 'filter'
          Feature.create :heading => h, :name => 'isOnlineOnly', :feature_type => 'Binary',
          :used_for => 'filter'
          Feature.create :heading => h, :name => 'toprated', :feature_type => 'Binary',
          :used_for => 'filter'
        end

        if h.name == 'Video Resolution'
          Feature.create :heading => h, :name => 'videoresolution720', :feature_type => 'Binary',
          :used_for => 'filter'
          Feature.create :heading => h, :name => 'videoresolution1080', :feature_type => 'Binary',
          :used_for => 'filter'
        end

        if h.name == 'New Technology'
          Feature.create :heading => h, :name => 'hdmi', :feature_type => 'Binary',
          :used_for => 'filter'
          Feature.create :heading => h, :name => 'touchscreen', :feature_type => 'Binary',
          :used_for => 'filter'
          Feature.create :heading => h, :name => 'imagestabilization', :feature_type => 'Binary',
          :used_for => 'filter'
          Feature.create :heading => h, :name => 'waterproof', :feature_type => 'Binary',
          :used_for => 'show, filter'
          Feature.create :heading => h, :name => 'oled', :feature_type => 'Binary',
          :used_for => 'filter'
          Feature.create :heading => h, :name => 'gps', :feature_type => 'Binary',
          :used_for => 'show, filter'
          Feature.create :heading => h, :name => 'projector', :feature_type => 'Binary',
          :used_for => 'filter'
          Feature.create :heading => h, :name => '3d', :feature_type => 'Binary',
          :used_for => 'show, filter'
          Feature.create :heading => h, :name => 'sweeppanorama', :feature_type => 'Binary',
          :used_for => 'show, filter'
          Feature.create :heading => h, :name => 'frontlcd', :feature_type => 'Binary',
          :used_for => 'show, filter'
      
        end
      end

      if h.product_type.name == 'tv_bestbuy'
        if h.name = 'General'
          Feature.create :heading => h, :name => 'price', :feature_type => 'Continuous',
          :used_for => 'filter, cluster, show', :larger_is_better => false, :min => 1, :max => 10000
          Feature.create :heading => h, :name => 'maxresolution', :feature_type => 'Continuous',
          :used_for => 'desc, filter, cluster, show'
          Feature.create :heading => h, :name => 'screensize', :feature_type => 'Continuous', 
          :used_for => 'desc, filter, cluster, show'
          Feature.create :heading => h, :name => 'power', :feature_type => 'Continuous',
          :used_for => 'desc, filter, cluster, show'
          Feature.create :heading => h, :name => 'brand', :feature_type => 'Categorical',
          :used_for => 'filter, show'
          Feature.create :heading => h, :name => 'displaytech', :feature_type => 'Categorical',
          :used_for => 'filter, show'
        end
      end

      if h.product_type.name == 'drive_bestbuy'
        if h.name = 'General'
          Feature.create :heading => h, :name => 'price', :feature_type => 'Continuous',
          :used_for => 'filter, cluster, show', :larger_is_better => false, :min => 1, :max => 10000
          Feature.create :heading => h, :name => 'brand', :feature_type => 'Categorical',
          :used_for => 'show, filter, cluster', :utility_weight => 5
          Feature.create :heading => h, :name => 'customerRating', :feature_type => 'Continuous',
          :used_for => 'show'
          Feature.create :heading => h, :name => 'includeInBox', :feature_type => 'Categorical',
          :used_for => 'show'
          Feature.create :heading => h, :name => 'interface', :feature_type => 'Categorical',
          :used_for => 'show, filter, cluster'
          Feature.create :heading => h, :name => 'dimensions', :feature_type => 'Categorical',
          :used_for => 'show'
          Feature.create :heading => h, :name => 'pc', :feature_type => 'Categorical',
          :used_for => 'show'
          Feature.create :heading => h, :name => 'mac', :feature_type => 'Categorical',
          :used_for => 'show'
          Feature.create :heading => h, :name => 'weight', :feature_type => 'Categorical',
          :used_for => 'show'
          Feature.create :heading => h, :name => 'softwareIncluded', :feature_type => 'Categorical',
          :used_for => 'show'
          Feature.create :heading => h, :name => 'systemRequirements', :feature_type => 'Categorical',
          :used_for => 'show'
          Feature.create :heading => h, :name => 'maximumDataTransferRate', :feature_type => 'Categorical',
          :used_for => 'show'
        end
        if h.name == 'USB Flash Drives'
          Feature.create :heading => h, :name => 'capacity', :feature_type => 'Categorical',
          :used_for => 'show'
          Feature.create :heading => h, :name => 'isReadyBoostCompliant', :feature_type => 'Categorical',
          :used_for => 'show'
          Feature.create :heading => h, :name => 'isSoftwareIncluded', :feature_type => 'Categorical',
          :used_for => 'show'
          Feature.create :heading => h, :name => 'typeOfMedia', :feature_type => 'Categorical',
          :used_for => 'show'
        end
        if h.name == 'External/Internal Hard Drives, Solid State Drives, Storage Accessories'
          Feature.create :heading => h, :name => 'overageSeekTime', :feature_type => 'Categorical',
          :used_for => 'show'
          Feature.create :heading => h, :name => 'dataBuffer', :feature_type => 'Categorical',
          :used_for => 'show'
          Feature.create :heading => h, :name => 'rotaionsPerMinute', :feature_type => 'Categorical',
          :used_for => 'show'
          Feature.create :heading => h, :name => 'storageCapacity', :feature_type => 'Categorical',
          :used_for => 'show'
        end
        if h.name == 'DVD & CD Drives'
          Feature.create :heading => h, :name => 'cdReadSpeed', :feature_type => 'Categorical',
          :used_for => 'show'
          Feature.create :heading => h, :name => 'cdRewriteSpeed', :feature_type => 'Categorical',
          :used_for => 'show'
          Feature.create :heading => h, :name => 'cdWriteSpeed', :feature_type => 'Categorical',
          :used_for => 'show'
          Feature.create :heading => h, :name => 'dvdReadSpeed', :feature_type => 'Categorical',
          :used_for => 'show'
          Feature.create :heading => h, :name => 'dvdRewriteSpeed', :feature_type => 'Categorical',
          :used_for => 'show'
          Feature.create :heading => h, :name => 'dvdWriteSpeed', :feature_type => 'Categorical',
          :used_for => 'show'
          Feature.create :heading => h, :name => 'dataAccessTime', :feature_type => 'Categorical',
          :used_for => 'show'
          Feature.create :heading => h, :name => 'internal', :feature_type => 'Categorical',
          :used_for => 'show'
          Feature.create :heading => h, :name => 'external', :feature_type => 'Categorical',
          :used_for => 'show'
        end
      end


    end

  end


  def self.down
    remove_index :features, [:heading_id, :name]
    drop_table :features
  end
end
