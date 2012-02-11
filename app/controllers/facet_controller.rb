class FacetController < ApplicationController
  layout "empty"
  
  def new
    if params[:type] =~ /Heading|Spacer/
      @new_facet = Facet.new(:product_type => Session.product_type, 
                :name => params[:type],
                :feature_type => params[:type],
                :used_for => params[:used_for])
    else
      f_type = ScrapingRule.find_all_by_product_type_and_local_featurename(Session.product_type, params[:name]).map{ |sr|
        sr.rule_type}.compact
      @new_facet = Facet.new(:product_type => Session.product_type, 
                :name => params[:name],
                :feature_type => f_type.first,
                :used_for => params[:used_for])
    end
  end
  
end
