class AccessoriesController < ApplicationController
  layout "plain"

  def initialize_constants
    @accessories_per_product_type = 10
    @accessory_types_per_bestselling = 5
    @top_n_limit_number = 2 # Number of items that can come from the same leaf node
    @selling_threshold = 10 # Number of sales the last item in a leaf node's display (top ten sold) must 
      #have in order for the leaf node to remain its own category (otherwise the category is bumped to its parent)
    @number_of_products = 5 # Number of products (bestselling) displayed for the categories wanted
  end
  
  def index
    initialize_constants()
    #----- change/add categories to be analyzed here -----#
    # Both FS and BB
    product_types = ["B20352","B21344","B30297"]
    # For Best Buy
    #product_types = ["B20352","B21344","B30297"] #B21344 for tvs, B20352 for laptops, B30297 for tablets
    # For Future Shop
    #product_types = ["F1002","F29958","Ftvs","F1953"]
    ids = get_products(product_types)
    render "index", :locals => {:best_sellers => ids}
  end
  
  def show
    initialize_constants()
    #product_types = [params[:id]]
    if params[:id] =~ /^[BF]/
      ids = get_products([params[:id]])
      if params.has_key?(:count)
        count = params[:count]
        params[:prod_acc_cats][params[:sku]] = [params[:acc_cat],params[:count]]
        render "show", :locals => {:cat_prods => ids, :prod_acc_cats => params[:prod_acc_cats], :count => count}
      else
        count = "-"
        prod_acc_cats = {}
        ids.each_pair do |category,products|
          products.each do |product|
            prod_acc_cats[product.sku] = [params[:acc_cat],"-"]
          end
        end
        render "show", :locals => {:cat_prods => ids, :prod_acc_cats => prod_acc_cats, :count => count}
      end
    else
      
      #product = get_product(params[:id])
      if params.has_key?(:count)
        count = params[:count]
      else
        count = "-"
      end
      render "show_single", :locals => {:product => get_product(params[:id]).first, :cat => params[:cat], :acc_cat => params[:acc_cat], :count => count}
    end
  end
  
  def get_products(product_types)
    initialize_constants()
    cat_ids = {}
    ids = {}
    product_types.each do |cat_id|
      if cat_id == "B30297" # List all categories with product types other than those wanted
        cat_ids[cat_id] = ["B29059","B20356","B31040","B31042","B32300"] # Only the actual tablets (non-accessory)
      else
        Session.new(cat_id)          # is it possible to create a session with multiple ids to avoid this?
        cat_ids[cat_id] = Session.product_type_leaves
      end
    end
    cat_ids.each_pair do |cat,leaves|  # Cycle through the leaf nodes wanted
      p_ids = []  
      ids[cat] = Product.joins("INNER JOIN `cat_specs` ON `products`.id = `cat_specs`.product_id").joins("INNER JOIN `cont_specs` ON `products`.id = `cont_specs`.product_id").where(cat_specs: {name:'product_type', value:leaves}, cont_specs: {name:'sum_store_sales'}).order("`cont_specs`.value DESC").limit(@number_of_products)
    end
    ids
  end
  
  def get_product(id)
    prod = Product.where(:id => id)
  end
end