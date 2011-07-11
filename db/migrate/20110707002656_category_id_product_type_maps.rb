class CategoryIdProductTypeMaps < ActiveRecord::Migration
  def self.up
    remove_column :category_id_product_type_maps, :product_type
      add_column :category_id_product_type_maps, :product_type_id, :integer

#    add_index :category_id_product_type_maps, [:product_type_id, :category_id], :unique => true
    ProductType.find_each do |t|
      if t.name == 'camera_bestbuy'
        CategoryIdProductTypeMap.create :product_type => t, :category_id => 22474
        CategoryIdProductTypeMap.create :product_type => t, :category_id => 28382
        CategoryIdProductTypeMap.create :product_type => t, :category_id => 28381
        CategoryIdProductTypeMap.create :product_type => t, :category_id => 20220
      end

      if t.name == 'tv_bestbuy'
        CategoryIdProductTypeMap.create :product_type => t, :category_id => 21344
      end

      if t.name == 'drive_bestbuy'
        CategoryIdProductTypeMap.create :product_type => t, :category_id => 20243
        CategoryIdProductTypeMap.create :product_type => t, :category_id => 20237
        CategoryIdProductTypeMap.create :product_type => t, :category_id => 20239
        CategoryIdProductTypeMap.create :product_type => t, :category_id => 30442
        CategoryIdProductTypeMap.create :product_type => t, :category_id => 20236
        CategoryIdProductTypeMap.create :product_type => t, :category_id => 29583        
      end
    end

  end

  def self.down
    #   remove_index :category_id_product_type_maps, [:product_type_id, :category_id]
    remove_column :category_id_product_type_maps, :product_type_id
    add_column :category_id_product_type_maps, :product_type, :string
  end
end
