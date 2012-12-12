class Equivalence < ActiveRecord::Base
  def self.fill
    eqs = [] #Equivalences to be updated
    #Maps product id, product object
    products_hash = Product.current_type.inject({}){|res, elem| res[elem.id] = elem; res}
    while !products_hash.empty?
      p_id, p = products_hash.first
      #Siblings is a symmetric and transitive relationship
      siblings = p.product_siblings.map(&:sibling_id)
      #while product bundles is non-symmetric
      bundles = p.product_bundles.map(&:bundle_id)+ProductBundle.find_all_by_bundle_id(p_id).map(&:product_id)
      bundle = bundles.first
      bundle_siblings = bundle ? Product.find(bundle).product_siblings.map(&:sibling_id) : []
      equiv_prod_ids = siblings + bundles + bundle_siblings << p_id
      
      eq_id = SecureRandom.uuid #Set a random eq_id for the group
      equiv_prod_ids.each do |equiv_prod_id|
        products_hash.delete(equiv_prod_id) #Remove to prevent duplicate processing
        eq = Equivalence.find_or_initialize_by_product_id(equiv_prod_id)
        eq.eq_id = eq_id
        eqs << eq
      end
    end
    Equivalence.import eqs, :on_duplicate_key_update => [:product_id, :eq_id]
  end
end
