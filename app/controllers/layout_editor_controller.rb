class LayoutEditorController < ApplicationController
  def index
    pid = Session.product_type
    respond_to do |format|
      format.html { redirect_to :action => 'show', :id => pid }
    end
  end
  
  def show
    pid = params[:id]

    @db_filters = Facet.find_all_by_product_type_and_used_for(pid, 'filter').sort_by!{|f| f.value }
    @db_sortby = Facet.find_all_by_product_type_and_used_for(pid, 'sortby').sort_by!{|f| f.value }
    @db_compare = Facet.find_all_by_product_type_and_used_for(pid, 'show').sort_by!{|f| f.value }
    
    results = ScrapingRule.find_all_by_product_type(pid).select{|sr| sr.rule_type =~ /Continuous|Categorical|Binary/}
    results = (results.nil? or results.empty?) ? [] : results.map(&:local_featurename).uniq
    @sr_filters = results.nil? ? [] : results.sort
    results = ScrapingRule.find_all_by_product_type(pid).select{|sr| sr.rule_type =~ /Continuous/}
    results = (results.nil? or results.empty?) ? [] : results.map(&:local_featurename).uniq
    @sr_sortby = results.nil? ? [] : results.sort
    @sr_compare = @sr_filters
  end
  
  def create
    product_type = Session.product_type
    Facet.update_layout(product_type, 'filter', params[:filter_set])
    Facet.update_layout(product_type, 'sortby', params[:sorting_set])
    Facet.update_layout(product_type, 'show', params[:compare_set])
    render :nothing => true
  end
end
