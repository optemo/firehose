class Facet < ActiveRecord::Base
  has_many :dynamic_facets, :dependent=>:delete_all
  after_save{ Maybe(dynamic_facets).each{|x| x.save}}
  
  def self.check_active
     facets_to_save = []
     Facet.where(product_type: Session.product_type, feature_type: 'Binary').each do |facet|
       products_counts = BinSpec.joins("INNER JOIN products on products.id=product_id").where(bin_specs: {name: facet.name, product_type: Session.product_type},products: {instock: 1}).count
       facet.active = (products_counts > 0 ? 1 : 0)
       facets_to_save << facet
     end
     Facet.import facets_to_save, :on_duplicate_key_update => [:active] if facets_to_save.size > 0
   end
   
   def self.get_display_type(f_type)
     case f_type
       when 'Continuous'
         'Slider'
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
     # determine which facets are in the facets table but not in the page and delete them
     page_facet_ids = facet_set.values.map{|f|f[0].to_i}
     existing_facets = Facet.find_all_by_used_for_and_product_type(used_for, product_type)
     to_delete = existing_facets.select{|f| !page_facet_ids.include?(f.id)}
     to_delete.each {|d| d.destroy}
     
     # update the facets given the input from the page
     facet_set.each_pair do |index, vals|
       id = vals[0]
       if Facet.exists?(id) and Facet.find(id).product_type == product_type
         fn = Facet.find(id)
       else
         fn = Facet.new()
       end
       
       fn[:feature_type] = vals[1]
       fn[:name] = vals[2]
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
       fn.save()
       
       if fn[:feature_type] == 'Heading' or fn[:feature_type] == 'Spacer'
          fn[:name] = fn[:feature_type] + fn.id.to_s
          fn.save()
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
     Facet.get_display_type(feature_type)
   end
end
