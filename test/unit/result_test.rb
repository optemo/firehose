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
    p1 = create(:product)
    p2 = create(:product)
    p3 = create(:product)
     create(:bin_spec, name:"featured")
    create(:bin_spec, name:"featured")
  
  end
end
