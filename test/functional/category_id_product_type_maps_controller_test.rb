require 'test_helper'

class CategoryIdProductTypeMapsControllerTest < ActionController::TestCase
  setup do
    @product_type = product_types(:one)
  end
  
  test "should get new" do
    get :new, :id => 20243, :product_type => @product_type
    assert_response :success
  end
  
  # test "should create category id product type map" do
  #   assert_difference('CategoryIdProductTypeMap.count') do
  #     post :create, category_id_product_type_map: {"product_type_id" => @product_type_id, "category_id"=>"99312"}
  #   end
  #   assert_redirected_to product_types_path + '?id=' + @product_type_id
  # end
  
  test "should destroy category id product type map" do
    assert_difference('CategoryIdProductTypeMap.count', -1) do
      category = CategoryIdProductTypeMap.first
      unless category.nil?
        delete :destroy, id: category.id
      end
    end
    assert_response :success
  end
end