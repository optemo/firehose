class ImagesIntoCatSpecs < ActiveRecord::Migration
  def self.up
    [:imggburl, :imgmsurl, :imgsurl, :imgmurl, :imglurl].each do |s|
      # Don't remove a column that isn't there
      remove_column :products, s if Product.new.methods.include?(s)
    end
  end

  def self.down
    [:imggburl, :imgmsurl, :imgsurl, :imgmurl, :imglurl].each do |s|
      # Don't add a column that already exists
      add_column :products, s, :string unless Product.new.methods.include?(s)
    end
  end
end
