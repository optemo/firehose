class Features < ActiveRecord::Migration
  def self.up
    create_table :features do |t|
      t.references :heading, :null => false
      t.string :name, :null => false
      t.string :feature_type, {:null => false, :default => 'Categorical'}
      t.string :used_for, :default => 'show'
      t.string :used_for_categories
      t.integer :used_for_order, :default => 9999
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
        if h.name == 'General'
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
        if h.name == 'General'
          # saleprice
          Feature.create :heading => h, :name => 'saleprice', :feature_type => 'Continuous',
          :used_for => 'filter, cluster, show, sortby', :larger_is_better => false, :min => 1, :max => 10000, :utility_weight => 5, :cluster_weight => 5

          # fblike
          Feature.create :heading => h, :name => 'fblike', :feature_type => 'Continuous',
          :used_for => 'sortby', :utility_weight => 5

          # brand
          Feature.create :heading => h, :name => 'brand', :feature_type => 'Categorical',
          :used_for => 'show, filter, cluster', :utility_weight => 5, :prefered => 'Canon, Sony, Nikon'

          # customerRating
          Feature.create :heading => h, :name => 'customerRating', :feature_type => 'Continuous',
          :used_for => 'show'

          # dimensions
          Feature.create :heading=>h, :name=>'dimensions', :feature_type=>'Categorical',
          :used_for=>'show'
          # weight
          Feature.create :heading=>h, :name=>'weight', :feature_type=>'Continuous', :used_for=>'show'
          # category
          Feature.create :heading=>h, :name=>'category', :feature_type=>'Categorical', :used_for=>'filter'
          # color
          Feature.create :heading => h, :name => 'color', :feature_type => 'Categorical',
          :used_for => 'filter, show'
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
          # isMac
          Feature.create :heading=>h, :name=>'isMac', :feature_type=>'Binary', :used_for=>'filter, show'
        end
        if h.name == 'USB Flash Drives' # 20243 
          # capacity
          Feature.create :heading => h, :name => 'capacity', :feature_type => 'Continuous',
          :used_for => 'filter, show', :used_for_categories=>'20243'
          # readPerSecond
          Feature.create :heading=>h, :name=>'readPerSecond', :feature_type=>'Continuous', :used_for=>'show', :used_for_categories=>'20243'
          # writePerSecond
          Feature.create :heading=>h, :name=>'writePerSecond', :feature_type=>'Continuous', :used_for=>'show', :used_for_categories=>'20243'
        end
        if h.name == 'External/Internal Hard Drives, Solid State Drives, Storage Accessories' #20237: 10169902; #20239: 10161382; #30442: 10156225 # 29583: 10163178
          Feature.create :heading=>h, :name=>'dataTransferRate', :feature_type=>'Continuous', :used_for=>'show', :used_for_categories=>'20237, 20239, 30442, 29583'
          Feature.create :heading => h, :name => 'seekTime', :feature_type => 'Categorical',
          :used_for => 'show', :used_for_categories=>'20237, 20239, 30442, 29583'
          Feature.create :heading => h, :name => 'dataBuffer', :feature_type => 'Categorical',
          :used_for => 'show', :used_for_categories=>'20237, 20239, 30442, 29583'
          Feature.create :heading => h, :name => 'rotaions', :feature_type => 'Categorical',
          :used_for => 'show', :used_for_categories=>'20237, 20239, 30442, 29583'
          Feature.create :heading => h, :name => 'interface', :feature_type => 'Categorical',
          :used_for => 'show', :used_for_categories=>'20237, 20239, 30442, 29583'
        end
        if h.name == 'DVD & CD Drives' # 20236: 10098842 
          Feature.create :heading => h, :name => 'cdReadSpeed', :feature_type => 'Continuous',
          :used_for => 'show', :used_for_categories=>'20236'
          Feature.create :heading => h, :name => 'cdRewriteSpeed', :feature_type => 'Continuous',
          :used_for => 'show', :used_for_categories=>'20236'
          Feature.create :heading => h, :name => 'cdWriteSpeed', :feature_type => 'Continuous',
          :used_for => 'show', :used_for_categories=>'20236'
          Feature.create :heading => h, :name => 'dvdReadSpeed', :feature_type => 'Continuous',
          :used_for => 'show', :used_for_categories=>'20236'
          Feature.create :heading => h, :name => 'dvdRewriteSpeed', :feature_type => 'Continuous',
          :used_for => 'show', :used_for_categories=>'20236'
          Feature.create :heading => h, :name => 'dvdWriteSpeed', :feature_type => 'Continuous',
          :used_for => 'show', :used_for_categories=>'20236'
          Feature.create :heading => h, :name => 'dataAccessTime', :feature_type => 'Continuous',
          :used_for => 'show', :used_for_categories=>'20236'
          Feature.create :heading => h, :name => 'isInternal', :feature_type => 'Binary',
          :used_for => 'show', :used_for_categories=>'20236'
          Feature.create :heading => h, :name => 'isExternal', :feature_type => 'Binary',
          :used_for => 'show', :used_for_categories=>'20236'
        end

        if h.name='Storage Accessories' 
          
        end
        
     end
    end
                 # Create scraping rules
        # img
        ScrapingRule.create :product_type=>'drive_bestbuy', :local_featurename=>'imgsurl', :remote_featurename=>'thumbnailImage', :regex=>'^(.*)/http://www.bestbuy.ca\1', :rule_type=>'cat', :active=>1, :priority=>0, :french=>0
        ScrapingRule.create :product_type=>'drive_bestbuy', :local_featurename=>'imgmurl', :remote_featurename=>'thumbnailImage', :regex=>'^(.*)55x55(.*)/http://www.bestbuy.ca\1100x100\2', :rule_type=>'cat', :active=>1, :priority=>0, :french=>0
        ScrapingRule.create :product_type=>'drive_bestbuy', :local_featurename=>'imglurl', :remote_featurename=>'thumbnailImage', :regex=>'^(.*)55x55(.*)/http://www.bestbuy.ca\1300x300\2', :rule_type=>'cat', :active=>1, :priority=>0, :french=>0
        ScrapingRule.create :product_type=>'drive_bestbuy', :local_featurename=>'img150url', :remote_featurename=>'thumbnailImage', :regex=>'^(.*)55x55(.*.?)/http://www.bestbuy.ca\1150x150\2', :rule_type=>'cat', :active=>1, :priority=>0, :french=>0
        # brand
        ScrapingRule.create :product_type=>'drive_bestbuy', :local_featurename=>'brand', :remote_featurename=>'brandName', :regex=>'.*', :rule_type=>'cat', :active=>1, :priority=>0, :french=>0
        # saleprice
        ScrapingRule.create :local_featurename => 'saleprice', :remote_featurename => 'salePrice', :regex => '\d*\.?\d+', :product_type => 'drive_bestbuy', :min=>1, :max=>10000, :rule_type=>'cont', :active=>1, :priority=>0, :french=>0
        # price
    ScrapingRule.create :local_featurename => 'price', :remote_featurename => 'regularPrice', :regex => '\d*\.?\d+', :product_type => 'drive_bestbuy', :min=>1, :max=>9432, :rule_type=>'cont', :active=>1, :priority=>0, :french=>0
    # customerRating
    ScrapingRule.create :product_type=>'drive_bestbuy', :local_featurename=>'customerRating', :remote_featurename=>'customerRating', :regex=>'.*', :rule_type=>'cont', :active=>1, :priority=>0, :french=>0
    # model
    ScrapingRule.create :local_featurename => 'model', :remote_featurename => 'name', :regex => '((KINGSTON|Kingston  TECHNOLOGY|Technology)|(PNY ELECTRONICS|Electronics)|(HEWLETT|Hewlett PACKARD|Packard)|(RETAIL|Retail PLUS|Plus)|(HIP|Hip STREET|Street)|(LEXAR|Lexar MEDIA|Media))\s+([^(]*)/\8', :product_type => 'drive_bestbuy', :rule_type=>'cat', :active=>1, :priority=>0, :french=>0
    ScrapingRule.create :local_featurename => 'model', :remote_featurename => 'name', :regex => '((EZ DUPE|Dupe)|(LG ELECTRONICS|Electronics)|(PC TREASURES|Treasures)|(HORNET|Hornet Tek|TEK)|(DATA|Data ROBOTICS|Robotics))\s+([^(]*)/\7', :product_type => 'drive_bestbuy', :rule_type=>'cat', :active=>1, :priority=>1, :french=>0
        ScrapingRule.create :local_featurename => 'model', :remote_featurename => 'name', :regex => '\w+\s+([^(]*)/\1', :product_type => 'drive_bestbuy', :rule_type=>'cat', :active=>1, :priority=>2, :french=>0
        # mpn
        ScrapingRule.create :product_type=>'drive_bestbuy', :local_featurename=>'mpn', :remote_featurename=>'modelNumber', :regex=>'.*', :rule_type=>'cat', :active=>1, :priority=>0, :french=>0
        # color
        ScrapingRule.create :product_type=>'drive_bestbuy', :local_featurename=>'color', :remote_featurename=>'specs..Colour', :regex=>'.*', :rule_type=>'cat', :active=>1, :priority=>0, :french=>0
    ScrapingRule.create :product_type=>'drive_bestbuy', :local_featurename=>'color', :remote_featurename=>'name', :regex=>'Red|Orange|Yellow|Green|Blue|Purple|Pink|White|Silver|Brown|Black', :rule_type=>'cat', :active=>1, :priority=>1, :french=>0
    ScrapingRule.create :product_type=>'drive_bestbuy', :local_featurename=>'color', :remote_featurename=>'name', :regex=>'Violet/Purple^^Gray/Silver^^Titanium/Silver^^Grey/Silver^^Gold/Orange', :rule_type=>'cat', :active=>1, :priority=>2, :french=>0    
        # title
        ScrapingRule.create :product_type=>'drive_bestbuy', :local_featurename=>'title', :remote_featurename=>'name', :regex=>'.*', :rule_type=>'cat', :active=>1, :priority=>0, :french=>0
        # isClearance
        ScrapingRule.create :product_type=>'drive_bestbuy', :local_featurename=>'isClearance', :remote_featurename=>'isClearance', :regex=>'[Tt]rue/1', :rule_type=>'bin', :active=>1, :priority=>0, :french=>0
        # isAdvertised
        ScrapingRule.create :product_type=>'drive_bestbuy', :local_featurename=>'isAdvertised', :remote_featurename=>'isAdvertised', :regex=>'[Tt]rue/1', :rule_type=>'bin', :active=>1, :priority=>0, :french=>0
        # isOnlineOnly
        ScrapingRule.create :product_type=>'drive_bestbuy', :local_featurename=>'isOnlineOnly', :remote_featurename=>'isOnlineOnly', :regex=>'[Tt]rue/1', :rule_type=>'bin', :active=>1, :priority=>0, :french=>0
        # toprated
        ScrapingRule.create :product_type=>'drive_bestbuy', :local_featurename=>'toprated', :remote_featurename=>'customerRating', :regex=>'4\.\d+/1', :rule_type=>'bin', :active=>1, :priority=>1, :french=>0
        ScrapingRule.create :product_type=>'drive_bestbuy', :local_featurename=>'toprated', :remote_featurename=>'customerRating', :regex=>'5\.\d+/1', :rule_type=>'bin', :active=>1, :priority=>0, :french=>0        
        # productURL
        ScrapingRule.create :product_type=>'drive_bestbuy', :local_featurename=>'productUrl', :remote_featurename=>'productUrl', :regex=>'.*', :rule_type=>'text', :active=>1, :priority=>0, :french=>0        
        # saleEndDate
        ScrapingRule.create :product_type=>'drive_bestbuy', :local_featurename=>'saleEndDate', :remote_featurename=>'SaleEndDate', :regex=>'.+', :rule_type=>'cat', :active=>1, :priority=>0, :french=>0        
        # category
    ScrapingRule.create :product_type=>'drive_bestbuy', :local_featurename=>'category', :remote_featurename=>'category_id', :regex=>'.*', :rule_type=>'cat', :active=>1, :priority=>0, :french=>0
        # capacity
    ScrapingRule.create :product_type=>'drive_bestbuy', :local_featurename=>'capacity', :remote_featurename=>'specs..Capacity', :regex=>'\d*\.?\d+', :rule_type=>'cont', :active=>1, :priority=>0, :french=>0
    ScrapingRule.create :local_featurename=>'capacity', :remote_featurename=>'specs..Storage Capacity', :regex=>'\d*\.?\d+', :product_type=>'drive_bestbuy', :rule_type=>'cont', :active=>1, :priority=>1, :french=>0
    ScrapingRule.create :local_featurename=>'capacity', :remote_featurename=>'specs..Storage Capacity', :regex=>'Nil|(Information Not Available)|(Not Applicable)/0', :product_type=>'drive_bestbuy', :rule_type=>'cont', :active=>1, :priority=>2, :french=>0
        ScrapingRule.create :product_type=>'drive_bestbuy', :local_featurename=>'capacity', :remote_featurename=>'name', :regex=>'(\d*\.?\d+)\s*([Tt]|[Gg]|[Mm])[Bb]/\1', :rule_type=>'cont', :active=>1, :priority=>3, :french=>0
        ScrapingRule.create :product_type=>'drive_bestbuy', :local_featurename=>'capacity', :remote_featurename=>'shortDescription', :regex=>'(\d*\.?\d+)\s*([Tt]|[Gg]|[Mm])[Bb]/\1', :rule_type=>'cont', :active=>1, :priority=>4, :french=>0
        ScrapingRule.create :product_type=>'drive_bestbuy', :local_featurename=>'capacity', :remote_featurename=>'longDescription', :regex=>'(\d*\.?\d+)\s*([Tt]|[Gg]|[Mm])[Bb]/\1', :rule_type=>'cont', :active=>1, :priority=>5, :french=>0
        # dimensions
        ScrapingRule.create :local_featurename=>'dimensions', :remote_featurename=>'specs..Dimensions', :regex=>'.*', :product_type=>'drive_bestbuy', :rule_type=>'', :active=>1, :priority=>0, :french=>0
        # weight
        ScrapingRule.create :local_featurename=>'weight', :remote_featurename=>'specs..Product Weight', :regex=>'.*', :product_type=>'drive_bestbuy', :rule_type=>'cat', :active=>1, :priority=>0, :french=>0
        # readPerSecond
    ScrapingRule.create :local_featurename=>'readPerSecond', :remote_featurename=>'specs..Maximum Data Transfer Rate', :regex=>'(\d*\.?\d+)\s*([Gg]|[Mm])[Bb][^\s]*\s+\(?Read/\1', :product_type=>'drive_bestbuy', :rule_type=>'cont', :active=>1, :priority=>0, :french=>0
    ScrapingRule.create :local_featurename=>'readPerSecond', :remote_featurename=>'specs..Maximum Data Transfer Rate', :regex=>'\d*\.?\d+', :product_type=>'drive_bestbuy', :rule_type=>'cont', :active=>1, :priority=>1, :french=>0
    ScrapingRule.create :local_featurename=>'readPerSecond', :remote_featurename=>'specs..Maximum Data Transfer Rate', :regex=>'(USB.*)|(Information Not Available)|(Not Applicable)/0', :product_type=>'drive_bestbuy', :rule_type=>'cont', :active=>1, :priority=>2, :french=>0
        ScrapingRule.create :local_featurename=>'readPerSecond', :remote_featurename=>'name', :regex=>'(\d*\.?\d+)\s*([Gg]|[Mm])[Bb][^\s]*\s+\(?Read/\1', :product_type=>'drive_bestbuy', :rule_type=>'cont', :active=>1, :priority=>3, :french=>0
        ScrapingRule.create :local_featurename=>'readPerSecond', :remote_featurename=>'name', :regex=>'(\d*\.?\d+)\s*([Gg]|[Mm])[Bb][^\s]*\s+/\1', :product_type=>'drive_bestbuy', :rule_type=>'cont', :active=>1, :priority=>4, :french=>0
    # writePerRate
            ScrapingRule.create :local_featurename=>'writePerSecond', :remote_featurename=>'specs..Maximum Data Transfer Rate', :regex=>'(\d*\.?\d+)\s*[Mm][Bb][^\s]*\s+\(?Read\.Write/\1', :product_type=>'drive_bestbuy', :rule_type=>'cont', :active=>1, :priority=>0, :french=>0
    ScrapingRule.create :local_featurename=>'writePerSecond', :remote_featurename=>'specs..Maximum Data Transfer Rate', :regex=>'(\d*\.?\d+)\s*[Mm][Bb][^\s]*\s+\(?Write/\1', :product_type=>'drive_bestbuy', :rule_type=>'cont', :active=>1, :priority=>1, :french=>0
    ScrapingRule.create :local_featurename=>'writePerSecond', :remote_featurename=>'specs..Maximum Data Transfer Rate', :regex=>'\d*\.?\d+', :product_type=>'drive_bestbuy', :rule_type=>'cont', :active=>1, :priority=>2, :french=>0
    ScrapingRule.create :local_featurename=>'writePerSecond', :remote_featurename=>'shortDescription', :regex=>'(\d*\.?\d+)\s*[Mm][Bb][^\s]*\s+\(?Read\.Write/\1', :product_type=>'drive_bestbuy', :rule_type=>'cont', :active=>1, :priority=>3, :french=>0
    ScrapingRule.create :local_featurename=>'writePerSecond', :remote_featurename=>'shortDescription', :regex=>'(\d*\.?\d+)\s*[Mm][Bb][^\s]*\s+\(?Write/\1', :product_type=>'drive_bestbuy', :rule_type=>'cont', :active=>1, :priority=>4, :french=>0
    # isMac
    ScrapingRule.create :local_featurename=>'isMac', :remote_featurename=>'specs..PC/Mac', :regex=>'Mac|MAC|Both|BOTH/1', :product_type=>'drive_bestbuy', :rule_type=>'bin', :active=>1, :priority=>0, :french=>0
    # rotations
    ScrapingRule.create :local_featurename=>'rotations', :remote_featurename=>'specs..Rotations Per Minute (RPM)', :regex=>'\d+', :product_type=>'drive_bestbuy', :rule_type=>'cont', :active=>1, :priority=>0, :french=>0
    ScrapingRule.create :local_featurename=>'rotations', :remote_featurename=>'specs..Rotations Per Minute (RPM)', :regex=>'(Information Not Available)|(Not Applicable)/0', :product_type=>'drive_bestbuy', :rule_type=>'cont', :active=>1, :priority=>1, :french=>0
        # seekTime
        ScrapingRule.create :local_featurename=>'seekTime', :remote_featurename=>'specs..Average Seek Time', :regex=>'(\d+)\s*ms/\1', :product_type=>'drive_bestbuy', :rule_type=>'cont', :active=>1, :priority=>0, :french=>0
    # interface
    ScrapingRule.create :local_featurename=>'interface', :remote_featurename=>'specs..Interface', :regex=>'.*', :product_type=>'drive_bestbuy', :rule_type=>'cat', :active=>1, :priority=>0, :french=>0
    # dataTransferRate
    ScrapingRule.create :local_featurename=>'dataTransferRate', :remote_featurename=>'specs..Maximum Data Transfer Rate', :regex=>'(\d*\.?\d+)\s*[Mm][Bb]/\1', :product_type=>'drive_bestbuy', :rule_type=>'cont', :active=>1, :priority=>0, :french=>0
    ScrapingRule.create :local_featurename=>'dataTransferRate', :remote_featurename=>'specs..Maximum Data Transfer Rate', :regex=>'(\d?\.?\d)\s*[Gg][Bb]/\1000', :product_type=>'drive_bestbuy', :rule_type=>'cont', :active=>1, :priority=>1, :french=>0
        # dataBuffer
        ScrapingRule.create :local_featurename=>'dataBuffer', :remote_featurename=>'specs..Data Buffer', :regex=>'\d{1,3}', :product_type=>'drive_bestbuy', :rule_type=>'cont', :active=>1, :priority=>0, :french=>0
        # cdReadSpeed
    ScrapingRule.create :local_featurename=>'cdReadSpeed', :remote_featurename=>'specs..CD Read Speed', :regex=>'\d*\.?\d+', :product_type=>'drive_bestbuy', :rule_type=>'cont', :active=>1, :priority=>0, :french=>0
    ScrapingRule.create :local_featurename=>'cdReadSpeed', :remote_featurename=>'specs..CD Read Speed', :regex=>'Nil|(Information Not Available)|(Not Applicable)/0', :product_type=>'drive_bestbuy', :rule_type=>'cont', :active=>1, :priority=>1, :french=>0        
        # cdRewriteSpeed
    ScrapingRule.create :local_featurename=>'cdRewriteSpeed', :remote_featurename=>'specs..CD Rewrite Speed', :regex=>'\d*\.?\d+', :product_type=>'drive_bestbuy', :rule_type=>'cont', :active=>1, :priority=>0, :french=>0
    ScrapingRule.create :local_featurename=>'cdRewriteSpeed', :remote_featurename=>'specs..CD Rewrite Speed', :regex=>'Nil|(Information Not Available)|(Not Applicable)/0', :product_type=>'drive_bestbuy', :rule_type=>'cont', :active=>1, :priority=>1, :french=>0        
        # cdWriteSpeed
    ScrapingRule.create :local_featurename=>'cdWriteSpeed', :remote_featurename=>'specs..CD Write Speed', :regex=>'\d*\.?\d+', :product_type=>'drive_bestbuy', :rule_type=>'cont', :active=>1, :priority=>0, :french=>0
    ScrapingRule.create :local_featurename=>'cdWriteSpeed', :remote_featurename=>'specs..CD Write Speed', :regex=>'Nil|(Information Not Available)|(Not Applicable)/0', :product_type=>'drive_bestbuy', :rule_type=>'cont', :active=>1, :priority=>1, :french=>0        
        # dataAccessTime
    ScrapingRule.create :local_featurename=>'dataAccessTime', :remote_featurename=>'specs..Data Access Time', :regex=>'\d*\.?\d+', :product_type=>'drive_bestbuy', :rule_type=>'cont', :active=>1, :priority=>0, :french=>0
    ScrapingRule.create :local_featurename=>'dataAccessTime', :remote_featurename=>'specs..Data Access Time', :regex=>'Nil|(Information Not Available)|(Not Applicable)/0', :product_type=>'drive_bestbuy', :rule_type=>'cont', :active=>1, :priority=>1, :french=>0        
        # dvdReadSpeed
    ScrapingRule.create :local_featurename=>'dvdReadSpeed', :remote_featurename=>'specs..DVD Read Speed', :regex=>'\d*\.?\d+', :product_type=>'drive_bestbuy', :rule_type=>'cont', :active=>1, :priority=>0, :french=>0
    ScrapingRule.create :local_featurename=>'dvdReadSpeed', :remote_featurename=>'specs..DVD Read Speed', :regex=>'Nil|(Information Not Available)|(Not Applicable)/0', :product_type=>'drive_bestbuy', :rule_type=>'cont', :active=>1, :priority=>0, :french=>0        
        # dvdRewriteSpeed
    ScrapingRule.create :local_featurename=>'dvdRewriteSpeed', :remote_featurename=>'specs..DVD Rewrite Speed', :regex=>'^\s*(\d{1,2})[Xx]/\1', :product_type=>'drive_bestbuy', :rule_type=>'cont', :active=>1, :priority=>0, :french=>0
    ScrapingRule.create :local_featurename=>'dvdRewriteSpeed', :remote_featurename=>'specs..DVD Rewrite Speed', :regex=>'Nil|(Information Not Available)|(Not Applicable)/0', :product_type=>'drive_bestbuy', :rule_type=>'cont', :active=>1, :priority=>1, :french=>0
        # dvd_rw
        ScrapingRule.create :local_featurename=>'dvd_rw', :remote_featurename=>'specs..DVD Rewrite Speed', :regex=>'^DVD\+RW\s*(\d{1,2})[Xx]/\1', :product_type=>'drive_bestbuy', :rule_type=>'cont', :active=>1, :priority=>0, :french=>0        
        # dvd-rw
        ScrapingRule.create :local_featurename=>'dvd-rw', :remote_featurename=>'specs..DVD Rewrite Speed', :regex=>'^DVD-RW\s*(\d{1,2})[Xx]/\1', :product_type=>'drive_bestbuy', :rule_type=>'cont', :active=>1, :priority=>0, :french=>0        
        # dvdWriteSpeed
    ScrapingRule.create :local_featurename=>'dvdWriteSpeed', :remote_featurename=>'specs..DVD Write Speed', :regex=>'^\s*(\d{1,2})[Xx]/\1', :product_type=>'drive_bestbuy', :rule_type=>'cont', :active=>1, :priority=>0, :french=>0
    ScrapingRule.create :local_featurename=>'dvdWriteSpeed', :remote_featurename=>'specs..DVD Write Speed', :regex=>'Nil|(Information Not Available)|(Not Applicable)/0', :product_type=>'drive_bestbuy', :rule_type=>'cont', :active=>1, :priority=>1, :french=>0
        # dvd_w
        ScrapingRule.create :local_featurename=>'dvd_w', :remote_featurename=>'specs..DVD Write Speed', :regex=>'^DVD\+W\s*(\d{1,2})[Xx]/\1', :product_type=>'drive_bestbuy', :rule_type=>'cont', :active=>1, :priority=>0, :french=>0        
        # dvd-w
        ScrapingRule.create :local_featurename=>'dvd-w', :remote_featurename=>'specs..DVD Write Speed', :regex=>'^DVD-W\s*(\d{1,2})[Xx]/\1', :product_type=>'drive_bestbuy', :rule_type=>'cont', :active=>1, :priority=>0, :french=>0        
        # isInternal
        ScrapingRule.create :local_featurename=>'isInternal', :remote_featurename=>'specs..Internal or External', :regex=>'[Ii]nternal/1', :product_type=>'drive_bestbuy', :rule_type=>'bin', :active=>1, :priority=>0, :french=>0        
        # isExternal
        ScrapingRule.create :local_featurename=>'isExternal', :remote_featurename=>'specs..Internal or External', :regex=>'[Ee]xternal/1', :product_type=>'drive_bestbuy', :rule_type=>'bin', :active=>1, :priority=>0, :french=>0        

  end


  def self.down
    ScrapingRule.delete_all(:product_type=>'drive_bestbuy')
    remove_index :features, [:heading_id, :name]
    drop_table :features
  end
end
