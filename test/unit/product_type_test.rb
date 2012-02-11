require 'test_helper'

class ProductTypeTest < ActiveSupport::TestCase

  test "name validation" do
    prod_type = build(:product_type, :name => nil)
    assert !prod_type.save, "product type should not be created without a name"
  end
  
  test "removing product_type and the category maps" do
    prod_type = product_types(:one)
    original_product_type_count = ProductType.count
    prod_type.destroy

    # ensure that there is one less product type
    assert_equal original_product_type_count - 1, ProductType.count
  end

end
