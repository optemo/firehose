class Equivalence < ActiveRecord::Base
  def self.fill
    eq_ar = []
    Product.current_type.each do |prod|
      #Siblings is a symmetric and transitive relationship
      #while product bundles is non-symmetric
      eq = Equivalence.find_or_initialize_by_product_id(prod.id)
      #Put product bundles back into Equivalences
      equivalences = prod.product_bundles.map(&:bundle_id)+ProductBundle.find_all_by_bundle_id(prod.id).map(&:product_id)+prod.product_siblings.map(&:sibling_id)
      #This is for taking bundles back out
      #equivalences = prod.product_siblings.map(&:sibling_id)

      if sibling = eq_ar.index{|p| equivalences.include? p.product_id}
        eq.eq_id = eq_ar[sibling].eq_id
      else
        eq.eq_id = SecureRandom.uuid
      end
      eq_ar << eq
    end
    Equivalence.import eq_ar, :on_duplicate_key_update => [:product_id, :eq_id]
  end
end
