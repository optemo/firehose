require 'test_helper'

class ProductTypesControllerTest < ActionController::TestCase
  setup do
    @product_type = create(:product_type)
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
  
  test "Change current product type" do
    post :index, :product_type => {id: 6}
    assert_equal Session.product_type, "drive_bestbuy", "The Session object should be set"
    get :index
    assert session[:current_product_type_id], "The session should be stored in a cookie"
  end
  
  test "should create product_type" do
    assert_difference('ProductType.count') do
      post :create, product_type: build(:product_type).attributes
    end
    assert_redirected_to product_types_path + '?id=' + assigns(:product_type).to_param
  end
  
  test "should show product_type" do
     get :show, id: @product_type.to_param
     assert_response :success
  end
  
  test "should destroy product_type" do
    assert_difference('ProductType.count', -1) do
      delete :destroy, id: @product_type.to_param
    end
    assert_redirected_to product_types_path + "?ajax=true"
  end
end
