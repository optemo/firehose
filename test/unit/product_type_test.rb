require 'test_helper'

class ProductTypeTest < ActiveSupport::TestCase

  test "name validation" do
    prod_type = build(:product_type, :name => nil)
    assert !prod_type.save, "product type should not be created without a name"
  end
    
  test "category id name validation" do
    # category_id must have a category_id and it should be 5 or more digits
    prod_type = create(:product_type)
    category_orphan = build(:category_id_product_type_map, :product_type => nil, :category_id => 45146)
    category1 = build(:category_id_product_type_map, :product_type => prod_type, :category_id => nil)
    category2 = build(:category_id_product_type_map, :product_type => prod_type, :category_id => 451)
    category3 = build(:category_id_product_type_map, :product_type => prod_type, :category_id => "X4514")
    category_valid = build(:category_id_product_type_map, :product_type => prod_type, :category_id => 45145)
    assert !category_orphan.save, "category id should not be created without a product_type"
    assert !category1.save, "category id should not be created without a name"
    assert !category2.save, "category id should have at least 5 digits"
    assert !category3.save, "category id should be only digits"
    assert category_valid.save, "valid category name"
  end

  test "assigning category ids to product type" do
    # create two valid category ids for the product type, then retrieve them
    prod_type = product_types(:one)
    category1 = category_id_product_type_maps(:one)
    category2 = category_id_product_type_maps(:two)

    found_first = false
    found_second = false
    prod_type.category_id_product_type_maps.each do |category|
      if (category == category1)
        found_first = true
      elsif (category == category2)
        found_second = true
      end
    end
    assert found_first
    assert found_second
  end
  
  test "removing product_type and the category maps" do
    prod_type = product_types(:one)
    category1 = category_id_product_type_maps(:one)
    original_category_count = CategoryIdProductTypeMap.count
    original_product_type_count = ProductType.count
    prod_type.destroy

    # ensure that there is one less product type
    assert_equal original_product_type_count - 1, ProductType.count
    # check that categories also got destroyed
    assert_not_equal original_category_count, CategoryIdProductTypeMap.count
  end

end
