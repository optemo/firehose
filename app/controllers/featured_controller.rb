class FeaturedController < ApplicationController
  layout "plain"
  NUMBER_OF_PRODUCTS = 5
  attr_accessor :topperformers
  @topperformers = {}
  
  def index
    #----- change/add categories to be analyzed here -----#
    product_types = ["B20352","B21344","B30297"] #B21344 for tvs, B20352 for laptops, B30297 for tablets
    ids = get_products(product_types)
    render "index", :locals => {:best_sellers => ids }
  end
  
  def show
    #product_types = [params[:id]]
    if params[:id] =~ /^[BF]/
      ids = get_products([params[:id]])
      render "show", :locals => {:cat_prods => ids}
    else
      product = get_product(params[:id])
      render "show_single", :locals => {:product => product.first, :cat => params[:cat]}
    end
  end
  
  def get_products (product_types)
    cat_ids = {}
    ids = {}
    product_types.each do |cat_id|
      if cat_id == "B30297" # List all categories with product types other than those wanted
        cat_ids[cat_id] = ["B29059","B20356","B31040","B31042","B32300"] # Only the actual tablets (non-accessory)
      else
        Session.new(cat_id)          # is it possible to create a session with multiple ids to avoid this?
        if Session.product_type_leaves.empty?
          cat_ids[cat_id] = cat_id
        else
          cat_ids[cat_id] = Session.product_type_leaves 
        end
      end
    end
    cat_ids.each_pair do |cat,leaves|  # Cycle through the leaf nodes wanted
      p_ids = []  
      ids[cat] = Product.joins("INNER JOIN `cat_specs` ON `products`.id = `cat_specs`.product_id").joins("INNER JOIN `cont_specs` ON `products`.id = `cont_specs`.product_id").where(cat_specs: {name:'product_type', value:leaves}, cont_specs: {name:'sum_store_sales'}).order("`cont_specs`.value DESC").limit(NUMBER_OF_PRODUCTS)
    end
    ids
  end
  
  def get_product (sku)
    prod = Product.where(:sku => sku)
  end
end