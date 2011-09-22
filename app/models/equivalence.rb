class Equivalence < ActiveRecord::Base
  def self.fill
    Equivalence.delete_all
    counter = 1
    eq_ar = []
    Product.find_each do |prod|
      #Siblings is a symmetric and transitive relationship
      #while product bundles is non-symmetric
      equivalences = prod.product_bundles.map(&:bundle_id)+ProductBundle.find_all_by_bundle_id(prod.id).map(&:product_id)+prod.product_siblings.map(&:sibling_id)
      if sibling = eq_ar.select{|p|equivalences.include? p.product_id}.first
        eq_ar << Equivalence.new(product_id: prod.id, eq_id: sibling.eq_id)
      else
        eq_ar << Equivalence.new(product_id: prod.id, eq_id: counter)
        counter += 1
      end
    end
    Equivalence.import eq_ar
  end
end
