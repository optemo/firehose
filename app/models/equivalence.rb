class Equivalence < ActiveRecord::Base
  def self.fill
    counter = Equivalence.maximum("eq_id")+1 #Equivalence class enumeration
    eq_ar = []
    Product.current_type.find_each do |prod|
      #Siblings is a symmetric and transitive relationship
      #while product bundles is non-symmetric
      eq = Equivalence.find_or_initialize_by_product_id(prod.id)
      #Take out product bundles from Equivalences
      #equivalences = prod.product_bundles.map(&:bundle_id)+ProductBundle.find_all_by_bundle_id(prod.id).map(&:product_id)+prod.product_siblings.map(&:sibling_id)
      equivalences = prod.product_siblings.map(&:sibling_id)

      if sibling = eq_ar.index{|p| equivalences.include? p.product_id}
        eq.eq_id = eq_ar[sibling].eq_id
      else
        eq.eq_id = counter
        counter += 1
      end
      eq_ar << eq
    end
    Equivalence.import eq_ar, :on_duplicate_key_update => [:product_id, :eq_id]
  end
end
