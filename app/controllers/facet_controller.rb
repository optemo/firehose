class FacetController < ApplicationController
  layout "empty"
  
  def new
    if params[:type] =~ /Heading|Spacer/
      @new_facet = Facet.new(:product_type_id => Session.product_type_id, 
                :name => params[:type],
                :feature_type => params[:type],
                :used_for => params[:used_for])
    else
      f_type = ScrapingRule.find_all_by_product_type_and_local_featurename(Session.product_type, params[:name]).select{|i| i.active}.map{ |sr|
        sr.rule_type}.delete_if{|i| i.nil?}
      factor_name = (params[:used_for] == 'sortby') ? (params[:name] + '_filter') : params[:name]
      @new_facet = Facet.new(:product_type_id => Session.product_type_id, 
                :name => factor_name,
                :feature_type => f_type.first,
                :used_for => params[:used_for])
    end
  end
  
end
