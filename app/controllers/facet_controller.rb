class FacetController < ApplicationController
  layout "empty"
  
  def new
    debugger
    if params[:type] =~ /Heading|Spacer/
      @new_facet = Facet.new(:product_type_id => Session.product_type_id, 
                :name => 'Empty',
                :feature_type => params[:type],
                :used_for => params[:used_for])
    else
      # FIXME: there could be several scraping rules that match! do find_all instead of find
      f_type = ScrapingRule.find_all_by_product_type_and_local_featurename(Session.product_type, params[:name]).map{
        |sr| 
        case sr.rule_type
        when 'cont'
          'Continuous'
        when 'cat'
          'Categorical'
        when 'bin'
          'Binary'
        end
      }
      @new_facet = Facet.new(:product_type_id => Session.product_type_id, 
                :name => params[:name],
                :feature_type => f_type.first,
                :used_for => params[:used_for])
    end
  end
end
