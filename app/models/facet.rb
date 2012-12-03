class Facet < ActiveRecord::Base
  has_many :dynamic_facets, :dependent=>:delete_all
  after_save{ Maybe(dynamic_facets).each{|x| x.save}}
  
  def self.check_active
     facets_to_save = []
     Facet.where(product_type: Session.product_type, feature_type: 'Binary').each do |facet|
       products_counts = BinSpec.joins("INNER JOIN (cat_specs, products) ON (`bin_specs`.product_id = `cat_specs`.product_id AND `bin_specs`.product_id = `products`.id)" ).where(bin_specs: {name: facet.name}, cat_specs: {name: "product_type", value: Session.product_type_leaves}, products: {instock: 1}).count
       facet.active = (products_counts > 0 ? 1 : 0)
       facets_to_save << facet
     end
     Facet.import facets_to_save, :on_duplicate_key_update => [:active] if facets_to_save.size > 0
   end
   
   def self.get_display_type(f_type, ui=nil)
     case f_type
       when 'Continuous'
         if ui.nil?
          'Ranges'
         else
           ui.capitalize
         end
       when 'Categorical'
         'Checkboxes for categories'
       when 'Binary'
         'Checkbox'
       when 'Heading'
         'Heading'
       when 'Spacer'
         'Spacer'
     end
   end
   
   def self.update_layout(product_type, used_for, facet_set)
     existing_facets = Facet.find_all_by_used_for_and_product_type(used_for, product_type)
     page_facet_ids = []
     page_facet_ids = facet_set.values.map{|f|f[0].to_i} unless facet_set == "null" or facet_set.nil? or facet_set.empty?
     to_delete = existing_facets.select{|f| !page_facet_ids.include?(f.id)}
     to_delete.each do |d|
       Facet.find_all_by_feature_type_and_product_type_and_used_for('Ordering', product_type, d.name).each { |o| o.destroy } if used_for == 'filter'
       d.destroy
     end
     return if facet_set == "null"
     # update the facets given the input from the page
     facet_set.each_pair do |index, vals|
       id = vals[0]
       if Facet.exists?(id) and Facet.find(id).product_type == product_type
         fn = Facet.find(id)
       else
         fn = Facet.new()
       end
       fn[:feature_type] = vals[1]
       facet_name = vals[2]
       fn[:name] = facet_name
       fn[:style] = case vals[5]
         when "true"
           'boldlabel'
         when "asc"
           'asc'
         when "desc"
           'desc'
         else
           ''
       end
       fn[:product_type] = product_type
       fn[:value] = index
       fn[:used_for] = used_for
       fn[:active] = 1
       
       if fn[:feature_type] == 'Continuous'
         fn[:ui] = (facet_name == "saleprice" && Session.retailer == 'F' ? 'slider' : 'ranges')
       end
       fn.save()
       
       if fn[:feature_type] == 'Heading' or fn[:feature_type] == 'Spacer'
          fn[:name] = fn[:feature_type] + fn.id.to_s
          fn.save()
       end
       if used_for == 'filter'
         cleared = vals[6]
         
         # save the ordering of the categories, if there is a list of categories as one of the input params
         current_order = Facet.find_all_by_feature_type_and_product_type_and_used_for('Ordering', product_type, facet_name)
         categories = vals[7..-1]
         unless categories.empty?
           # delete the existing order of the categories not present in the new order
           ordering_to_delete = current_order.select{ |p| !categories.include?(p.name) }
           ordering_to_delete.each {|instance| instance.destroy}
         end
         categories.each_with_index do |name, index|
           fn = Facet.find_or_initialize_by_name_and_feature_type_and_product_type_and_used_for(name, 'Ordering', product_type, facet_name)
           fn.value = index
           fn.active = true
           fn.save
         end
         # delete the existing ordering if the order was manually cleared
         if cleared == "true"
             current_order.each {|instance| instance.destroy}
         end
       end
       # store the display name as a translation string
       suffix = (fn[:style] == "asc" or fn[:style] == "desc") ? ('_' + fn[:style]) : ''
       unless (fn[:feature_type] == 'Spacer')
         I18n.backend.store_translations(I18n.locale,
           product_type => {
             used_for => {
               fn[:name] + suffix => { 'name' => vals[3] }
             }
           })
          unless (fn[:feature_type] == 'Heading' or used_for == 'sortby')
           I18n.backend.store_translations(I18n.locale, 
             product_type => {
               used_for => {
                 fn[:name] + suffix => { 'unit' => vals[4] }
               } 
             })
          end
       end
     end
   end
   
   def get_display
     Facet.get_display_type(feature_type, self.ui)
   end
end
