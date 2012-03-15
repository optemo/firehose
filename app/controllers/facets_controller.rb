class FacetsController < ApplicationController
  layout "application", except: [:new]

  def index
    parent_types = Session.product_type_path.reverse
    # if the facets for this product_type are empty, default to the nearest ancestor with facets
    i = 0
    f_type = nil
    @p_type = parent_types[i]
    while i <= parent_types.length - 1
      @p_type = parent_types[i]
      no_facets = Facet.find_all_by_product_type_and_used_for(@p_type, 'filter').empty? and Facet.find_all_by_product_type_and_used_for(@p_type, 'sortby').empty? and Facet.find_all_by_product_type_and_used_for(@p_type, 'show').empty?
      break unless no_facets
      i += 1
    end
    
    @db_filters = Facet.find_all_by_product_type_and_used_for(@p_type, 'filter').sort_by!{|f| f.value }
    @db_sortby = Facet.find_all_by_product_type_and_used_for(@p_type, 'sortby').sort_by!{|f| f.value }
    @db_compare = Facet.find_all_by_product_type_and_used_for(@p_type, 'show').sort_by!{|f| f.value }    
    
    # also inherit ancestors' scraping rules
    current_and_parents_rules = ScrapingRule.where(:product_type => parent_types)
    type_rules = current_and_parents_rules.select{|sr| sr.rule_type =~ /Continuous|Categorical|Binary/}
    results = (type_rules.nil? or type_rules.empty?) ? [] : type_rules.map(&:local_featurename).uniq
    # add custom rules
    custom_rules = Customization.find_all_by_product_type(parent_types)
    type_custom_rules = custom_rules.select{|sr| sr.rule_type =~ /Continuous|Categorical|Binary/}
    results += (type_custom_rules.nil? or type_custom_rules.empty?) ? [] : type_custom_rules.map(&:feature_name).uniq
    @sr_filters = results.nil? ? [] : results.sort
    @sr_compare = @sr_filters
    
    cont_rules = current_and_parents_rules.select{|sr| sr.rule_type =~ /Continuous/}  
    cont_custom_rules = custom_rules.select{|sr| sr.rule_type =~ /Continuous/}
    results = (cont_rules.nil? or cont_rules.empty?) ? [] : cont_rules.map(&:local_featurename).uniq
    results += (cont_custom_rules.nil? or cont_custom_rules.empty?) ? [] : cont_custom_rules.map(&:feature_name).uniq
    @sr_sortby = results.nil? ? [] : results.sort
  end
  
  def create
    product_type = Session.product_type
    Facet.update_layout(product_type, 'filter', params[:filter_set])
    Facet.update_layout(product_type, 'sortby', params[:sorting_set])
    Facet.update_layout(product_type, 'show', params[:compare_set])
    render :nothing => true
  end
  
  def new
    @p_type = Session.product_type
    if params[:type] =~ /Heading|Spacer/
      @new_facet = Facet.new(:product_type => Session.product_type, 
                :name => params[:type],
                :feature_type => params[:type],
                :used_for => params[:used_for])
    else
      # find the rule type by looking at the scraping rules for this type, and if not found, its ancestors
      product_path = Session.product_type_path.reverse
      i = 0
      f_type = nil
      
      custom_rule = Customization.find_all_by_product_type(product_path).select{ |cr| cr.feature_name == params[:name]}
      unless custom_rule.empty?
        f_type = custom_rule.first.rule_type
      else
        while (f_type.nil? or f_type.empty?)
          raise "NotFound" if i > product_path.length - 1
          p_type = product_path[i]        
          f_type = ScrapingRule.find_all_by_product_type_and_local_featurename(p_type, params[:name]).map{ |sr|
            sr.rule_type}.compact
          i += 1
        end
        f_type = f_type.first
      end
      @new_facet = Facet.new(:product_type => Session.product_type, 
                :name => params[:name],
                :feature_type => f_type,
                :used_for => params[:used_for])
    end
  end
  
end
