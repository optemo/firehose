require 'test_helper'

class EquivalenceTest < ActiveSupport::TestCase
  setup do
    Session.new
  end
  
  test "creating equivalence classes" do
    sibling1 = create(:product)
    sibling2 = create(:product)
    non_sibling = create(:product)
    sibling_spec1 = create(:product_sibling, product_id: sibling1.id, sibling_id: sibling2.id)
    sibling_spec2 = create(:product_sibling, product_id: sibling2.id, sibling_id: sibling1.id)
    Equivalence.fill()    
    # check that the equivalence model has 3 records
    assert_equal Equivalence.all.length, 3
    # check that equivalence for the siblings is the same but different from the non sibling 
    assert_equal Equivalence.find_by_product_id(sibling1.id).eq_id, Equivalence.find_by_product_id(sibling2.id).eq_id
    assert_not_equal Equivalence.find_by_product_id(sibling1.id).eq_id, Equivalence.find_by_product_id(non_sibling.id).eq_id
  end
end