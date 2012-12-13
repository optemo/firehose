class Equivalence < ActiveRecord::Base
  def self.fill
    eqs = [] # Equivalences to be updated
    # Maps product id to product object
    products_hash = Product.current_type.inject({}){|res, elem| res[elem.id] = elem; res}
    while !products_hash.empty?
      p_id, p = products_hash.first
      
      # If it is a bundle, find the main product. 
      bundle = ProductBundle.find_by_bundle_id(p_id)
      
      if not bundle.nil?
        main_product = Product.find(bundle.product_id)
        if not main_product.nil?
          p = main_product
          p_id = main_product.id
        end
      end

      # We find all the siblings of the product and add them to the equivalence class.
      # For each sibling we add all the bundles to the class.  And for each bundle,
      # we add all of its siblings to the class.      
      siblings = [p]
      siblings += p.product_siblings.map{ |rec| Product.find(rec.sibling_id) }.compact
      
      equiv_prod_ids = {}
      
      siblings.each do |product| 
        equiv_prod_ids[product.id] = true
        product.product_bundles.each do |bundle|
          equiv_prod_ids[bundle.bundle_id] = true
          bundle_product = Product.find(bundle.bundle_id)
          if not bundle_product.nil?
            bundle_product.product_siblings.each do |bundle_sibling|
              equiv_prod_ids[bundle_sibling.sibling_id] = true
            end
          end
        end 
      end
      
      eq_id = SecureRandom.uuid #Set a random eq_id for the group
      equiv_prod_ids.keys.each do |equiv_prod_id|
        products_hash.delete(equiv_prod_id) # Remove to prevent duplicate processing
        eq = Equivalence.find_or_initialize_by_product_id(equiv_prod_id)
        eq.eq_id = eq_id
        eqs << eq
      end
    end
    Equivalence.import eqs, :on_duplicate_key_update => [:product_id, :eq_id]
  end
end
