require 'test_helper'

class EquivalenceTest < ActiveSupport::TestCase
  setup do
    Session.new
  end
  
  test "creating equivalence classes for siblings" do
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
  
  test "check products with different product types set" do
    p1 = create(:typed_product, product_type: "B22474")
    p2 = create(:typed_product, product_type: "B28381")
    sibling_non = create(:typed_product, product_type: "B22474")
    sibling_spec1 = create(:product_sibling, product_id: p1.id, sibling_id: p2.id)
    sibling_spec2 = create(:product_sibling, product_id: p2.id, sibling_id: p1.id)
    
    Session.new "B22474"
    Equivalence.fill()
    
    # check that the equivalence model has 3 records + 1 fixture
    assert_equal 4, Equivalence.count
    
    # check that equivalence for the siblings is the same but different from the non sibling 
    assert_equal Equivalence.find_by_product_id(p1.id).eq_id, Equivalence.find_by_product_id(p2.id).eq_id
    assert_not_equal Equivalence.find_by_product_id(p1.id).eq_id, Equivalence.find_by_product_id(sibling_non.id).eq_id
    
    # Should get same results after running Equivalence.fill in the other sibling's category.
    Session.new "B28381"
    Equivalence.fill()
    
    # check that the equivalence model has 3 records + 1 fixture
    assert_equal 4, Equivalence.count
    
    # check that equivalence for the siblings is the same but different from the non sibling 
    assert_equal Equivalence.find_by_product_id(p1.id).eq_id, Equivalence.find_by_product_id(p2.id).eq_id
    assert_not_equal Equivalence.find_by_product_id(p1.id).eq_id, Equivalence.find_by_product_id(sibling_non.id).eq_id
  end
  
  test "check bundles and bundle siblings being handled correctly" do
    p1 = create(:typed_product)
    bp1 = create(:typed_product)
    b1 = create(:product_bundle, product: p1, bundle_id: bp1.id)
    
    # Create a product with two bundles.
    p5 = create(:typed_product)
    bp5 = create(:typed_product)
    bp6 = create(:typed_product)
    b5 = create(:product_bundle, product: p5, bundle_id: bp5.id)
    b6 = create(:product_bundle, product: p5, bundle_id: bp6.id)

    # The products are siblings.
    create(:product_sibling, product_id: p1.id, sibling_id: p5.id)
    create(:product_sibling, product_id: p5.id, sibling_id: p1.id)
    
    # Two of the bundles are siblings.
    create(:product_sibling, product_id: bp1.id, sibling_id: bp5.id)
    create(:product_sibling, product_id: bp5.id, sibling_id: bp1.id)
    
    Equivalence.fill()
    # check that the equivalence model has 5 records (+ 1 fixture)
    assert_equal 6, Equivalence.count
    # all these products should have the same eq_id (+ 1 fixture)
    groups = Equivalence.all.group_by(&:eq_id)
    assert_equal 2, groups.size, "The created products are in the same equivalence class"
    
    group_1 = groups.find { |key, group| group.size == 1 }
    assert_not_nil group_1
    group_1 = group_1[1].map(&:product_id)
    group_2 = groups.find { |key, group| group.size == 5 }
    assert_not_nil group_2
    group_2 = group_2[1].map(&:product_id)
    
    assert group_2.include? p1.id
    assert group_2.include? bp1.id
    assert group_2.include? p5.id
    assert group_2.include? bp5.id
    assert group_2.include? bp6.id
  end
  
  test "bundle in different type from product and Equivalence.fill called on bundle type" do
    p1 = create(:typed_product, product_type: "B22474")
    bp1 = create(:typed_product, product_type: "B28381")
    b1 = create(:product_bundle, product: p1, bundle_id: bp1.id)
    
    # Process type containing bundle 
    Session.new "B28381"
    Equivalence.fill
    
    # check that the equivalence model has 2 records
    assert_equal 2, Equivalence.count
    
    # check that equivalence id is the same for the bundle and the main product 
    assert_equal Equivalence.find_by_product_id(p1.id).eq_id, Equivalence.find_by_product_id(bp1.id).eq_id
  end
end

