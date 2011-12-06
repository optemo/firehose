require 'test_helper'

class ProductTypesControllerTest < ActionController::TestCase
  setup do
    @product_type = product_types(:one)
  end

  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:product_types)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create product_type" do
    assert_difference('ProductType.count') do
      post :create, product_type: @product_type.attributes
    end

    assert_redirected_to product_type_path(assigns(:product_type))
  end

  test "should show product_type" do
    get :show, id: @product_type.to_param
    assert_response :success
  end

  test "should get edit" do
    get :edit, id: @product_type.to_param
    assert_response :success
  end

  test "should update product_type" do
    put :update, id: @product_type.to_param, product_type: @product_type.attributes
    assert_redirected_to product_type_path(assigns(:product_type))
  end

  test "should destroy product_type" do
    assert_difference('ProductType.count', -1) do
      delete :destroy, id: @product_type.to_param
    end
    
    assert_redirected_to product_types_path + "?ajax=true"
  end
end
