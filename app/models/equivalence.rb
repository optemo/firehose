class Equivalence < ActiveRecord::Base
  def self.fill
    Equivalence.delete_all
    counter = 1
    eq_ar = []
    Product.find_each do |prod|
      if sibling = eq_ar.select{|p|prod.product_siblings.map(&:sibling_id).include? p.product_id}.first
        eq_ar << Equivalence.new(product_id: prod.id, eq_id: sibling.eq_id)
      else
        eq_ar << Equivalence.new(product_id: prod.id, eq_id: counter)
        counter += 1
      end
    end
    Equivalence.import eq_ar
  end
end
