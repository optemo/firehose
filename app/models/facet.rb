class Facet < ActiveRecord::Base
  require 'ruby-debug'  
  has_many :dynamic_facets, :dependent=>:delete_all
  after_save{ Maybe(dynamic_facets).each{|x| x.save}}
  def self.count_products(p_type_name = nil)
     product_type_name = (Session.product_type ||= 'camera_bestbuy') if p_type_name.nil?
     product_type_name ||= p_type_name
     facets_to_save = []
     Facet.all.each do |facet|
       if facet.feature_type == 'Binary'
         if product_type_name == ProductType.where(["id=?", facet.product_type_id]).first.name 
           products_counts = BinSpec.count(:conditions =>["name=? and bin_specs.product_type=? and value is not null and value > 0",  facet.name, product_type_name], :joins => "INNER JOIN products on products.id=product_id and products.instock=1")
           facet.active = (products_counts > 0 ? 1 : 0)
           facets_to_save << facet
         end
       end
     end
     Facet.import facets_to_save, :on_duplicate_key_update => [:active] if facets_to_save.size > 0
   end
end
