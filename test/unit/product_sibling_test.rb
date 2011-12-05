require 'test_helper'

class TextSpecTest < ActiveSupport::TestCase
  
  setup do
     Session.new
     create(:product, id: 10, sku:10159584, instock:1)
     create(:product, id: 11, sku:10159585, instock:1)
     create(:product, id: 12, sku:10159586, instock:1)
     create(:product, id: 13, sku:10159587, instock:1)
     create(:cat_spec, product_id:10, name:"color", value:"www.bestby.ca/purple")
     create(:cat_spec, product_id:11, name:"color", value:"www.bestby.ca/red")
     create(:cat_spec, product_id:12, name:"color", value:"www.bestby.ca/yellow")
     create(:cat_spec, product_id:13, name:"color", value:"www.bestby.ca/green")
   end
   
   test "make sure 0 insert works" do
    create(:text_spec, product_id:11, name:"relations", value:'[{"sku": "10159587","type": "Else"}]')  
    #there should be 0 records in the PrdouctSibling table
    assert_equal(0,ProductSibling.get_relations.num_inserts)
   end

  test "make sure color relationship is symmetric (R(a,b) => R(b,a))" do

    t1 = create(:text_spec, product_id:11, name:"relations", value:'[{"sku": "10159587","type": "Variant"}]')
    #create(:text_spec, product_id:13, name:"relations", value:'[{"sku": "10159585","type": "Variant"}]')
    ProductSibling.get_relations
    #there should be 2 records in the PrdouctSibling table
    assert_equal(2, ProductSibling.all.length)
    # the t1.product_id should be also appread as the sibling_id
    assert(ProductSibling.find_by_sibling_id(t1.product_id))
  end
  
  test "make sure color relationship is transitive (R(a,b) & R(b,c)=> R(a,c))" do
    
    t1 = create(:text_spec, product_id:11, name:"relations", value:'[{"sku": "10159587","type": "Variant"}, {"sku": "10159586","type": "Variant"}]')
    ProductSibling.get_relations
    #there should be 6 records in the PrdouctSibling table (11 -> 12, 11-> 13 ,12->13 -> 12->11, 13->11, 13->12)
    assert_equal(6, ProductSibling.all.length)
    # there should be two records with product_id equals to 12
    assert_equal(2, ProductSibling.count(:conditions => "product_id= 12"))

  end
  
  test "make sure color relationship is transitive for more than two relations)" do
    
    create(:text_spec, product_id:11, name:"relations", value:'[{"sku": "10159587","type": "Variant"}, {"sku": "10159586","type": "Variant"},{"sku": "10159584","type": "Variant"}]')
    ProductSibling.get_relations
    #there should be 12 records in the PrdouctSibling table
    assert_equal(12, ProductSibling.all.length)
  end
end