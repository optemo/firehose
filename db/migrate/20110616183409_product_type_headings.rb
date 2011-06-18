class ProductTypeHeadings < ActiveRecord::Migration
  def self.up
    create_table :product_type_headings do |t|
      t.references :product_type, :null => false
      t.string :name, :null => false
      t.timestamps
    end
    add_index :product_type_headings, [:product_type_id, :name], :unique => true

      ProductType.find_each do |t|
      if t.name == 'camera_bestbuy'
        ProductTypeHeading.create :product_type => t, :name => 'General'
        ProductTypeHeading.create :product_type => t, :name => 'Status'
        ProductTypeHeading.create :product_type => t, :name => 'Video Resolution'
        ProductTypeHeading.create :product_type => t, :name => 'New Technology'
      end

      if t.name == 'tv_bestbuy'
        ProductTypeHeading.create :product_type => t, :name => 'General'
      end

      if t.name == 'drive_bestbuy'
        ProductTypeHeading.create :product_type => t, :name => 'General'
        ProductTypeHeading.create :product_type => t, :name => 'USB Flash Drives'
        ProductTypeHeading.create :product_type => t, :name => 'External/Internal Hard Drives, Solid State Drives, Storage Accessories'
        ProductTypeHeading.create :product_type => t, :name => 'DVD & CD Drives'
      end
    end
    
  end



  def self.down
    remove_index :product_type_headings, [:product_type_id, :name]
    drop_table :product_type_headings
  end
end
