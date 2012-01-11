class LayoutEditorController < ApplicationController
  def index
    pid = Session.product_type_id
    respond_to do |format|
      format.html { redirect_to :action => 'show', :id => pid }
    end
  end
  
  def show
    id = params[:id]
    @product_type = ProductType.find(id)
    @db_filters = Facet.find_all_by_product_type_id_and_used_for(id, 'filter').sort_by!{|f| f.value }
    @db_sortby = Facet.find_all_by_product_type_id_and_used_for(id, 'sortby').sort_by!{|f| f.value }
    @db_compare = Facet.find_all_by_product_type_id_and_used_for(id, 'show').sort_by!{|f| f.value }
    
    p_type = ProductType.find(id).name
    results = ScrapingRule.find_all_by_product_type(p_type).select!{|sr| sr.active == true && sr.rule_type =~ /cont|cat|bin/}
    @sr_filters = results.nil? ? [] : results.map(&:local_featurename).uniq!.sort!
    results = ScrapingRule.find_all_by_product_type(p_type).select!{|sr| sr.active == true && sr.rule_type =~ /cont/}
    results = (results.nil? or results.empty?) ? [] : results.map(&:local_featurename).uniq!
    @sr_sortby = results.nil? ? [] : results.sort!
    @sr_compare = @sr_filters
  end
  
  def create
    # process params[:filter_set]
    # iterate over the values [in order of the keys] -- .each_pair
    # start by removing all the facets for that product_type [and filter / sortby / show]
    product_type = Session.product_type_id
    debugger
    Facet.update_layout(product_type, 'filter', params[:filter_set])
    Facet.update_layout(product_type, 'sortby', params[:sorting_set])
    Facet.update_layout(product_type, 'show', params[:compare_set])
  end

  def update
    puts 'in update'
  end
end
