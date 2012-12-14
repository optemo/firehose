require 'test_helper'

class ProductSiblingTest < ActiveSupport::TestCase
  
  setup do
    Session.new
    create(:typed_product, id: 10, sku:10159584)
    create(:typed_product, id: 11, sku:10159585)
    create(:typed_product, id: 12, sku:10159586)
    create(:typed_product, id: 13, sku:10159587)
    create(:cat_spec, product_id:10, name:"color", value:"purple")
    create(:cat_spec, product_id:11, name:"color", value:"red")
    create(:cat_spec, product_id:12, name:"color", value:"yellow")
    create(:cat_spec, product_id:13, name:"color", value:"green")
   end
   
  test "Check type must be Variant" do
    create(:text_spec, product_id:11, name:"relations", value:'[{"sku": "10159587","type": "Else"}]')
      
    # there should be 0 records in the ProductSibling table
    assert_equal(0,ProductSibling.all.size)
  end

  test "If no color attribute, relationship is not created" do
    create(:typed_product, id: 14, sku:10159588)
    t1 = create(:text_spec, product_id:11, name:"relations", value:'[{"sku": "10159588","type": "Variant"}]')
    t2 = create(:text_spec, product_id:14, name:"relations", value:'[{"sku": "10159585","type": "Variant"}]')
    ProductSibling.get_relations
    assert_equal(0, ProductSibling.all.length)
  end
  
  test "make sure color relationship is symmetric (R(a,b) => R(b,a))" do
    t1 = create(:text_spec, product_id:11, name:"relations", value:'[{"sku": "10159587","type": "Variant"}]')
    ProductSibling.get_relations
    assert_equal(2, ProductSibling.all.length)
    
    rec_1 = ProductSibling.find_by_product_id(t1.product_id)
    assert_not_nil rec_1
    assert_equal 13, rec_1.sibling_id
    assert_equal "color", rec_1.name
    assert_equal "green", rec_1.value
    
    rec_2 = ProductSibling.find_by_sibling_id(t1.product_id)
    assert_not_nil rec_2
    assert_equal 13, rec_2.product_id
    assert_equal "color", rec_2.name
    assert_equal "red", rec_2.value
  end
  
  test "bundles can be siblings only with other bundles" do
    b1 = create(:typed_product, id: 50, sku: "B01")
    b2 = create(:typed_product, id: 51, sku: "B02")

    create(:bin_spec, product_id: 50, name: "isBundle", value: true)
    create(:bin_spec, product_id: 51, name: "isBundle", value: true)

    create(:cat_spec, product_id: 50, name: "color", value: "purple")
    create(:cat_spec, product_id: 51, name: "color", value: "red")
    
    # Define relationships with a bundle and a non-bundle
    create(:text_spec, product_id: 50, name: "relations", value: '[{"sku": "B02", "type": "Variant"}, {"sku": "10159585","type": "Variant"}]')
    ProductSibling.get_relations
    
    # Only two sibling records should have been created.
    assert_equal(2, ProductSibling.all.length)
    
    rec_1 = ProductSibling.find_by_product_id(b1.id)
    assert_not_nil rec_1
    assert_equal 51, rec_1.sibling_id
    assert_equal "color", rec_1.name
    assert_equal "red", rec_1.value
    
    rec_2 = ProductSibling.find_by_sibling_id(b1.id)
    assert_not_nil rec_2
    assert_equal 51, rec_2.product_id
    assert_equal "color", rec_2.name
    assert_equal "purple", rec_2.value
  end

  test "check two siblings groups" do
    t1 = create(:text_spec, product_id:10, name:"relations", value:'[{"sku": "10159585","type": "Variant"}]')
    t2 = create(:text_spec, product_id:12, name:"relations", value:'[{"sku": "10159587","type": "Variant"}]')
    ProductSibling.get_relations
    assert_equal(4, ProductSibling.all.length)
    
    sibs = ProductSibling.find_all_by_product_id(10)
    assert_not_nil sibs
    assert_equal 1, sibs.size
    assert_equal 11, sibs[0].sibling_id
    assert_equal "red", sibs[0].value
    
    sibs = ProductSibling.find_all_by_product_id(11)
    assert_not_nil sibs
    assert_equal 1, sibs.size
    assert_equal 10, sibs[0].sibling_id
    assert_equal "purple", sibs[0].value
    
    sibs = ProductSibling.find_all_by_product_id(12)
    assert_not_nil sibs
    assert_equal 1, sibs.size
    assert_equal 13, sibs[0].sibling_id
    assert_equal "green", sibs[0].value

    sibs = ProductSibling.find_all_by_product_id(13)
    assert_not_nil sibs
    assert_equal 1, sibs.size
    assert_equal 12, sibs[0].sibling_id
    assert_equal "yellow", sibs[0].value
  end

  test "make sure old sibling records are used if they already exist" do
    t1 = create(:text_spec, product_id:11, name:"relations", value:'[{"sku": "10159587","type": "Variant"}]')
    ProductSibling.get_relations
    assert_equal 2, ProductSibling.all.length
    rec_1 = ProductSibling.find_by_product_id(t1.product_id)
    assert_not_nil rec_1
    rec_2 = ProductSibling.find_by_sibling_id(t1.product_id)
    assert_not_nil rec_2
    
    ProductSibling.get_relations    
    assert_equal 2, ProductSibling.all.length
    new_rec_1 = ProductSibling.find_by_product_id(t1.product_id)
    assert_not_nil new_rec_1
    assert_equal rec_1.id, new_rec_1.id
    new_rec_2 = ProductSibling.find_by_sibling_id(t1.product_id)
    assert_not_nil new_rec_2
    assert_equal rec_2.id, new_rec_2.id
  end
  
  test "make sure old sibling records are removed if the relationship has been broken" do
    t1 = create(:text_spec, product_id:11, name:"relations", value:'[{"sku": "10159587","type": "Variant"}]')
    t2 = create(:text_spec, product_id:10, name:"relations", value:'[{"sku": "10159586","type": "Variant"}]')
    ProductSibling.get_relations
    assert_equal 4, ProductSibling.all.length
    rec_1 = ProductSibling.find_by_product_id(t1.product_id)
    assert_not_nil rec_1
    rec_2 = ProductSibling.find_by_sibling_id(t1.product_id)
    assert_not_nil rec_2
    rec_3 = ProductSibling.find_by_product_id(t2.product_id)
    assert_not_nil rec_3
    rec_4 = ProductSibling.find_by_sibling_id(t2.product_id)
    assert_not_nil rec_4
    
    t2.destroy
    ProductSibling.get_relations    
    assert_equal 2, ProductSibling.all.length
    new_rec_1 = ProductSibling.find_by_product_id(t1.product_id)
    assert_not_nil new_rec_1
    assert_equal rec_1.id, new_rec_1.id
    new_rec_2 = ProductSibling.find_by_sibling_id(t1.product_id)
    assert_not_nil new_rec_2
    assert_equal rec_2.id, new_rec_2.id
  end

  test "Check transitivity: R(a,b) & R(a,c) => R(b,c)" do
    t1 = create(:text_spec, product_id:11, name:"relations", value:'[{"sku": "10159587","type": "Variant"}, {"sku": "10159586","type": "Variant"}]')
    ProductSibling.get_relations
    
    # there should be 6 records in the ProductSibling table (11 -> 12, 11 -> 13, 12 -> 11, 13 -> 11, 12 -> 13, 13 -> 12)
    assert_equal(6, ProductSibling.all.length)
    
    # there should be two records with product_id equals to 12
    assert_equal(2, ProductSibling.count(:conditions => "product_id = 12"))
    
    rec_1 = ProductSibling.find_by_product_id_and_sibling_id(12, 13)
    assert_not_nil rec_1
    assert_equal "color", rec_1.name
    assert_equal "green", rec_1.value
    
    rec_2 = ProductSibling.find_by_product_id_and_sibling_id(13, 12)
    assert_not_nil rec_2
    assert_equal "color", rec_2.name
    assert_equal "yellow", rec_2.value
  end
  
  test "Check transitivity: R(a,b) & R(b,c) => R(a,c)" do
    t1 = create(:text_spec, product_id:11, name:"relations", value:'[{"sku": "10159586","type": "Variant"}]')
    t2 = create(:text_spec, product_id:12, name:"relations", value:'[{"sku": "10159587","type": "Variant"}]')
    ProductSibling.get_relations
    
    # there should be 6 records in the ProductSibling table (11 -> 12, 11 -> 13, 12 -> 11, 13 -> 11, 12 -> 13, 13 -> 12)
    assert_equal(6, ProductSibling.all.length)
    
    # there should be two records with product_id equals to 13
    assert_equal(2, ProductSibling.count(:conditions => "product_id = 13"))
    
    rec_1 = ProductSibling.find_by_product_id_and_sibling_id(11, 13)
    assert_not_nil rec_1
    assert_equal "color", rec_1.name
    assert_equal "green", rec_1.value
    
    rec_2 = ProductSibling.find_by_product_id_and_sibling_id(13, 11)
    assert_not_nil rec_2
    assert_equal "color", rec_2.name
    assert_equal "red", rec_2.value
  end

  test "make sure color relationship is transitive (for more than two relations)" do
    create(:text_spec, product_id:11, name:"relations", value:'[{"sku": "10159587","type": "Variant"}, {"sku": "10159586","type": "Variant"}, {"sku": "10159584","type": "Variant"}]')
    ProductSibling.get_relations
    # there should be 12 records in the ProductSibling table
    assert_equal(12, ProductSibling.all.length)
  end
  
  test "siblings span product types" do
    create(:typed_product, product_type: "B22474", id: 50, sku: "100")
    create(:typed_product, product_type: "B28381", id: 51, sku: "101")
    create(:cat_spec, product_id: 50, name: "color", value: "purple")
    create(:cat_spec, product_id: 51, name: "color", value: "red")
    t1 = create(:text_spec, product_id: 50, name: "relations", value: '[{"sku": "101","type": "Variant"}]')
    t2 = create(:text_spec, product_id: 51, name: "relations", value: '[{"sku": "100","type": "Variant"}]')
    
    Session.new "B22474"
    ProductSibling.get_relations
    
    # One side of the relationship is created.
    assert_equal 1, ProductSibling.all.size
    rec_1 = ProductSibling.find_by_product_id_and_sibling_id(50, 51)
    assert_not_nil rec_1
    
    Session.new "B28381"
    ProductSibling.get_relations
    
    # The other side of the relationship is created.
    assert_equal 2, ProductSibling.all.size
    rec_1 = ProductSibling.find_by_product_id_and_sibling_id(50, 51)
    assert_not_nil rec_1
    rec_2 = ProductSibling.find_by_product_id_and_sibling_id(51, 50)
    assert_not_nil rec_2

    # On a second iteration, no new records created.    
    Session.new "B22474"
    ProductSibling.get_relations
    Session.new "B28381"
    ProductSibling.get_relations
    
    assert_equal 2, ProductSibling.all.size
    rec_1 = ProductSibling.find_by_product_id_and_sibling_id(50, 51)
    assert_not_nil rec_1
    rec_2 = ProductSibling.find_by_product_id_and_sibling_id(51, 50)
    assert_not_nil rec_2

    # Break the relationship and verify records are cleaned up.
    t1.destroy
    t2.destroy
        
    Session.new "B22474"
    ProductSibling.get_relations

    assert_equal 1, ProductSibling.all.size

    Session.new "B28381"
    ProductSibling.get_relations
    
    assert_equal 0, ProductSibling.all.size
  end
end

