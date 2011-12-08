require 'test_helper'


class ResultTest < ActiveSupport::TestCase


  test "Find bundles" do
    create :cat_spec, name: "padding", value: 'pillow', product: create(:product, sku: "101")
    create :text_spec, name: "bundle", value: '[{"sku": "101"}]', product: create(:product, sku: "102")
    create :text_spec, name: "bundle", value: '[{"sku": "101"}]', product: create(:product, sku: "102", instock: false)
    Session.new
    Result.find_bundles
    assert_equal 1, ProductBundle.count, "The bundle was found and created, and only instock ones"
    assert_equal 'pillow', Product.find_by_sku("102").cat_specs.find_by_name("padding").value, "Missing specs should be copied over from the original value"
  end
  
  test "upkeep_post" do 
    p1 = create(:product, id: 10)
    p2 = create(:product, id:11)
    p3 = create(:product,id: 12)
    p4 = create(:product, id: 13, instock: false)
    p5 = create(:product, id: 14)
    
    create :bin_spec, name:"featured", product_id: p4.id, product_type: p4.product_type
    create :bin_spec, name:"featured", product_id: p5.id, product_type: p5.product_type
    create :bin_spec, name:"onsale", product_id: p1.id, product_type: p1.product_type
    create :bin_spec, name:"onsale", product_id: p2.id, product_type: p2.product_type
    create :cat_spec, name:"saleEndDate", product_id: p4.id, product_type: p4.product_type, value: "07-12-2012 11:00:00 PM"
    create :cat_spec, name:"saleEnddate", product_id: p1.id, product_type: p1.product_type, value: "07-12-2011 1:00:00 PM"
    create :cat_spec, name:"saleEnddate", product_id: p2.id, product_type: p2.product_type, value: "07-12-2012 3:00:00 PM"
    create :cat_spec, name:"saleEnddate", product_id: p3.id, product_type: p3.product_type, value: "07-12-2012 00:00:00 PM"
    
    Result.upkeep_post();
    
    assert_nil(BinSpec.find_by_product_id(p1.id), "Product p1 is not on sale anymore")
    assert_equal(true, BinSpec.find_by_product_id(p2.id).value, "Product p1 is on sale now")
    assert( BinSpec.find_by_product_id_and_name(p4.id, "onsale"), "Product p4 is added to on sale items in BinSpec")
    assert(BinSpec.find_by_product_id(p3.id) , "Product p3 is added to on sale items")
  
  end
end
