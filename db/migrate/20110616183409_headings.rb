class Headings < ActiveRecord::Migration
  def self.up
    create_table :headings do |t|
      t.references :product_type, :null => false
      t.string :name, :null => false
      t.integer :show_order, :default => 9999
      t.timestamps
    end
    add_index :headings, [:product_type_id, :name], :unique => true

      ProductType.find_each do |t|
      if t.name == 'camera_bestbuy'
        Heading.create :product_type => t, :name => 'General'
        Heading.create :product_type => t, :name => 'Status'
        Heading.create :product_type => t, :name => 'Video Resolution'
        Heading.create :product_type => t, :name => 'New Technology'
      end

      if t.name == 'tv_bestbuy'
        Heading.create :product_type => t, :name => 'General'
      end

      if t.name == 'drive_bestbuy'
        Heading.create :product_type => t, :name => 'General'
        Heading.create :product_type => t, :name => 'USB Flash Drives'
        Heading.create :product_type => t, :name => 'External/Internal Hard Drives, Solid State Drives, Storage Accessories'
        Heading.create :product_type => t, :name => 'DVD & CD Drives'
      end
    end
    
  end



  def self.down
    remove_index :headings, [:product_type_id, :name]
    drop_table :headings
  end
end
