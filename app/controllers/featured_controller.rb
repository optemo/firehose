class FeaturedController < ApplicationController
  layout "plain"
  def index
    products = ["10176955", "10164172","10164834","10164836","10164921","10164960","10162371","10162372","10166498","10139191","10173487","10173486"]
    @products = BinSpec.find_all_by_name("featured").map{|bs|Product.find(bs.product_id)}
    @topperformers = Product.where(:sku => products, :instock=>1).reverse
    #@topperformers = Product.where(:sku => ["10164976", "10154265", "10164980", "10140085", "10162368", "10164411", "10156032", "10164837", "10162370", "10163470"])
  end
end
