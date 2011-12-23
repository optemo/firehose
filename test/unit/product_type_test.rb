require 'test_helper'

class ProductTypeTest < ActiveSupport::TestCase

  test "name validation" do
    prod_type = build(:product_type, :name => nil)
    assert !prod_type.save, "product type should not be created without a name"
  end
    
  test "category id validation" do
    # category_id must have a category_id and it should be 5 or more digits
    prod_type = create(:product_type)
    category_orphan = build(:category_id_product_type_map, :product_type => nil, :name => "a", :category_id => 45146)
    category1 = build(:category_id_product_type_map, :product_type => prod_type, :name => "b", :category_id => nil)
    category2 = build(:category_id_product_type_map, :product_type => prod_type, :name => "c", :category_id => 451)
    category3 = build(:category_id_product_type_map, :product_type => prod_type, :name => "d", :category_id => "X4514")
    category4 = build(:category_id_product_type_map, :product_type => prod_type, :name => nil, :category_id => 400)
    category5 = build(:category_id_product_type_map, :product_type => prod_type, :name => "d", :category_id => 45145)
    category_valid = build(:category_id_product_type_map, :product_type => prod_type, :name => "e", :category_id => 45145)
    category_duplicate = build(:category_id_product_type_map, :product_type => prod_type, :name => "e", :category_id => 45145)
    assert !category_orphan.save, "category id should not be created without a product_type"
    assert !category1.save, "category id should not be created without an id"
    assert !category2.save, "category id should have at least 5 digits"
    assert !category3.save, "category id should be only digits"
    assert !category4.save, "category should have a name"
    assert category_valid.save, "valid category id"
    assert !category_duplicate.save, "shouldn't have two categories with the same id for a product type"
  end

  test "assigning category ids to product type" do
    # create two valid category ids for the product type, then retrieve them
    prod_type = product_types(:two)
    category1 = category_id_product_type_maps(:three)
    category2 = category_id_product_type_maps(:four)
    found_first = false
    found_second = false
    prod_type.category_id_product_type_maps.each do |category|
      if (category == category1)
        found_first = true
      elsif (category == category2)
        found_second = true
      end
    end
    assert found_first, "category id found for product"
    assert found_second, "category id found for product"
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
