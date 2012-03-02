class FeaturedController < ApplicationController
  layout "plain"
  NUMBER_OF_PRODUCTS = 5
  
  def index
    
    # change/add categories to be analyzed here
    product_types = ["B30297"] #B21344 for tvs, B20352 for laptops, B30297 for tablets, B20404 for movies
    cat_ids = {}
    ids = {}
    product_types.each do |cat_id|
      if cat_id == "B30297" # List all categories with product types other than those wanted
        cat_ids[cat_id] = ["B29059","B20356","B31040","B31042","B32300"]
      else
        Session.new(cat_id)          # is it possible to create a session with multiple ids to avoid this?
        cat_ids[cat_id] = Session.product_type_leaves
      end
    end
    cat_ids.each_pair do |cat,leaves|  # Cycle through the leaf nodes wanted
      p_ids = []  
      ids[cat] = Product.joins("INNER JOIN `cat_specs` ON `products`.id = `cat_specs`.product_id").joins("INNER JOIN `cont_specs` ON `products`.id = `cont_specs`.product_id").where(cat_specs: {name:'product_type', value:leaves}, cont_specs: {name:'sum_store_sales'}).order("`cont_specs`.value DESC").limit(NUMBER_OF_PRODUCTS)
    end

    @products = BinSpec.find_all_by_name("featured").map{|bs|Product.find(bs.product_id)}
    @topperformers = ids
  end
end