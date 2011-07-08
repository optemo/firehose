class ProductTypes < ActiveRecord::Migration
  def self.up
    create_table :product_types do |t|
      t.string :name, :null=>false 
      t.string :layout, :default=>'assist'
      t.timestamps
    end

    add_index :product_types, :name, :unique => true


    ProductType.create :name => 'camera_bestbuy',
    :layout => 'assist'

    ProductType.create :name => 'tv_bestbuy',
    :layout => 'assist'

    ProductType.create :name => 'drive_bestbuy',
    :layout => 'assist'
  

  end

  def self.down
    remove_index :product_types, :name
    drop_table :product_types
  end
end
