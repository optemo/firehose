require 'test_helper'


class ResultTest < ActiveSupport::TestCase
  
  test "upkeep_post" do 
    p1 = create :typed_product
    p2 = create :typed_product
    p3 = create :typed_product
    p4 = create :typed_product, instock: false
    p5 = create :typed_product
    
    create :bin_spec, name:"featured", product_id: p4.id
    create :bin_spec, name:"featured", product_id: p5.id
    create :bin_spec, name:"onsale", product_id: p1.id
    create :bin_spec, name:"onsale", product_id: p2.id
    create :cat_spec, name:"saleEndDate", product_id: p4.id, value: "07-12-2012 11:00:00 PM"
    create :cat_spec, name:"saleEnddate", product_id: p1.id, value: "07-12-2011 1:00:00 PM"
    create :cat_spec, name:"saleEnddate", product_id: p2.id, value: "07-12-2012 3:00:00 PM"
    create :cat_spec, name:"saleEnddate", product_id: p3.id, value: "07-12-2012 00:00:00 PM"
    
    Result.upkeep_post();
    
    assert_nil(BinSpec.find_by_product_id(p1.id), "Product p1 is not on sale anymore")
    assert_equal(true, BinSpec.find_by_product_id(p2.id).value, "Product p1 is on sale now")
    assert( BinSpec.find_by_product_id_and_name(p2.id, "onsale"), "Product p4 is added to on sale items in BinSpec")
    assert(BinSpec.find_by_product_id(p3.id) , "Product p3 is added to on sale items")
  
  end
end
