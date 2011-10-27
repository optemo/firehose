class Facet < ActiveRecord::Base
  has_many :dynamic_facets, :dependent=>:delete_all
  after_save{ Maybe(dynamic_facets).each{|x| x.save}}
  
  def self.check_active
     facets_to_save = []
     Facet.where(id: Session.product_type_id, feature_type: 'Binary').each do |facet|
       products_counts = BinSpec.joins("INNER JOIN products on products.id=product_id").where(bin_specs: {name: facet.name, product_type: Session.product_type},products: {instock: 1}).count
       facet.active = (products_counts > 0 ? 1 : 0)
       facets_to_save << facet
     end
     Facet.import facets_to_save, :on_duplicate_key_update => [:active] if facets_to_save.size > 0
   end
end
