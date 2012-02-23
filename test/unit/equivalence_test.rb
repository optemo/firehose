require 'test_helper'

class EquivalenceTest < ActiveSupport::TestCase
  setup do
    Session.new
  end
  
  test "creating equivalence classes" do
    s1 = create(:typed_product)
    s2 = create(:typed_product)
    sibling_non = create(:typed_product)
    sibling_spec1 = create(:product_sibling, product_id: s1.id, sibling_id: s2.id)
    sibling_spec2 = create(:product_sibling, product_id: s2.id, sibling_id: s1.id)
    Equivalence.fill()
    # check that the equivalence model has 3 records + 1 fixture
    assert_equal 4, Equivalence.count
    # check that equivalence for the siblings is the same but different from the non sibling 
    assert_equal Equivalence.find_by_product_id(s1.id).eq_id, Equivalence.find_by_product_id(s2.id).eq_id
    assert_not_equal Equivalence.find_by_product_id(s1.id).eq_id, Equivalence.find_by_product_id(sibling_non.id).eq_id
  end
end