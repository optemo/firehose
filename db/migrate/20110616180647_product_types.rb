class ProductTypes < ActiveRecord::Migration
  def self.up
    create_table :product_types do |t|
      t.string :name, :null=>false 
      t.string :layouts, :default=>'assist'
      t.string :category_id, :null=>false
      t.timestamps
    end

    add_index :product_types, :name, :unique => true


    ProductType.create :name => 'camera_bestbuy',
    :layouts => 'assist', :category_id => '20218'

    ProductType.create :name => 'tv_bestbuy',
    :layouts => 'assist', :category_id => '21344'

    ProductType.create :name => 'drive_bestbuy',
    :layouts => 'assist', :category_id => '20243, 20237, 20239, 30442, 20236, 29583'
  

  end

  def self.down
    remove_index :product_types, :name
    drop_table :product_types
  end
end
