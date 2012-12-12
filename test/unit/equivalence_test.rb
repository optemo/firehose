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
  
  test "check products with different product_types set" do
    p1 = create(:typed_product)
    p2 = create(:typed_product, product_type: "B2003")
    assert_equal "B2003", p2.cat_specs.find_by_name("product_type").value
    sibling_non = create(:typed_product)
    sibling_spec1 = create(:product_sibling, product_id: p1.id, sibling_id: p2.id)
    sibling_spec2 = create(:product_sibling, product_id: p2.id, sibling_id: p1.id)
    
    Equivalence.fill()
    # check that the equivalence model has 3 records + 1 fixture
    assert_equal 4, Equivalence.count
    # check that equivalence for the siblings is the same but different from the non sibling 
    assert_equal Equivalence.find_by_product_id(p1.id).eq_id, Equivalence.find_by_product_id(p2.id).eq_id
    assert_not_equal Equivalence.find_by_product_id(p1.id).eq_id, Equivalence.find_by_product_id(sibling_non.id).eq_id
  end
  
  test "check bundles being handled correctly" do
    p1 = create(:typed_product)
    bp1 = create(:typed_product)
    b1 = create(:product_bundle, product: bp1, bundle_id: p1.id)
    
    p2 = create(:typed_product, product_type: "B2003")
    bp2 = create(:typed_product)
    b2 = create(:product_bundle, product: bp2, bundle_id: p2.id)

    create(:product_sibling, product_id: p1.id, sibling_id: p2.id)
    create(:product_sibling, product_id: p2.id, sibling_id: p1.id)
    create(:product_sibling, product_id: bp1.id, sibling_id: bp2.id)
    create(:product_sibling, product_id: bp2.id, sibling_id: bp1.id)
    
    Equivalence.fill()
    # check that the equivalence model has 3 records + 1 fixture
    assert_equal 5, Equivalence.count
    # all these products should be in the same eq_id + plus the fixture
    assert_equal 2, Equivalence.all.group_by(&:eq_id).count, "All equivalences in one group"
  end
end