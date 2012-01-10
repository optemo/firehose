class LayoutEditorController < ApplicationController
  def index
    pid = Session.product_type_id
    respond_to do |format|
      format.html { redirect_to :action => 'show', :id => pid }
    end
  end
  
  def show
    id = params[:id]
    @product_type = ProductType.find(params[:id])
    @old_filters = Facet.find_all_by_product_type_id_and_used_for(id, 'filter').sort_by!{|f| f.value }
    
    @old_sortby = Facet.find_all_by_product_type_id_and_used_for(id, 'sortby')
    @old_compare = Facet.find_all_by_product_type_id_and_used_for(id, 'show')
    
    p_type = ProductType.find(id).name
    @all_filters = ScrapingRule.find_all_by_product_type(p_type).select!{|sr| sr.active == true && sr.rule_type =~ /cont|cat|bin/}.map(&:local_featurename).uniq!.sort!
    
    @all_sortby = ScrapingRule.find_all_by_product_type_and_rule_type(p_type, 'cont').map(&:local_featurename)
    @all_compare = ScrapingRule.find_all_by_product_type(p_type).map(&:local_featurename)
  end

  def create
    # process params[:filter_set]
    # iterate over the values [in order of the keys] -- .each_pair
    params[:filter_set].each_pair do |index, vals|
      debugger
    end
    # key: use list.length - key.to_i to compute the 'value'
    # each_value is TYPE <- feature_type
    # dbname <- name
    # display, [nothing for now, will be the name]
    # styled[t/f] <- style
    # also set the product_type ['product_type_id']
    # also set used_for to filter
    # also set active to 1
    puts 'in create'
  end

  def update
    puts 'in update'
    
  end
end
