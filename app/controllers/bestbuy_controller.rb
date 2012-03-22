class BestbuyController < AccessoriesController
  layout "plain"
  
  def index
    initialize_constants()
    # Laptops: B20352, TVs: B21344, Tablets: B30297, Cameras: B20218, DSLRs: B20222
    product_types = ["B20352","B30297","B21344","B20218","B20222"]
    ids = get_products(product_types)
    render "index", :locals => {:best_sellers => ids}
  end
  
  def show
    initialize_constants()
    # The bestsellers do not have a count (accessories do...)
    if params.has_key?(:count)
      count = params[:count]
    else
      count = "-"
    end
    # Check if request is for a product type or a product
    if params[:id] =~ /^[BF]/ # if product type
      ids = get_products([params[:id]])
      unless count == "-"
        params[:prod_acc_cats][params[:sku]] = [params[:acc_cat],params[:count]]
        render "show", :locals => {:cat_prods => ids, :prod_acc_cats => params[:prod_acc_cats], :count => count}
      else
        prod_acc_cats = {}
        ids.each_pair do |category,products|
          products.each do |product|
            prod_acc_cats[product.sku] = [params[:acc_cat],"-"]
          end
        end
        render "show", :locals => {:cat_prods => ids, :prod_acc_cats => prod_acc_cats, :count => count}
      end
    else  # if product
      render "show_single", :locals => {:product => get_product(params[:id]).first, :cat => params[:cat], :acc_cat => params[:acc_cat], :count => count}
    end
  end
end