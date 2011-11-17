class FeaturedController < ApplicationController
  layout "plain"
  def index
    @products = BinSpec.find_all_by_name_and_product_type("featured", "camera_bestbuy").map{|bs|Product.find(bs.product_id)}
    @topperformers = Product.where(:sku => ["10164976", "10154265", "10164980", "10140085", "10162368", "10164411", "10156032", "10164837", "10162370", "10163470"])
  end
end
