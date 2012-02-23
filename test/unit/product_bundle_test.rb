require 'test_helper'

class ProductBundleTest < ActiveSupport::TestCase
  setup do
    Session.new
  end
  
  test "Find bundles" do
    create :cat_spec, name: "padding", value: 'pillow', product: create(:typed_product, sku: "101")
    create :text_spec, name: "bundle", value: '[{"sku": "101"}]', product: create(:typed_product, sku: "102")
    create :text_spec, name: "bundle", value: '[{"sku": "101"}]', product: create(:typed_product, sku: "103", instock: false)
    ProductBundle.get_relations
    assert_equal 2, ProductBundle.count, "The bundle was found and created, and including out of stock ones"
    assert_equal 'pillow', Product.find_by_sku("102").cat_specs.find_by_name("padding").try(:value), "Missing specs should be copied over from the original value"
  end
end