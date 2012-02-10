require 'test_helper'

class ProductTypesControllerTest < ActionController::TestCase
  setup do
    @product_type = create(:product_type)
  end

  test "should get index" do
      get :index
      assert_equal Session.product_type, "camera_bestbuy", "The Session product type should be set"
      assert session[:current_product_type_id], "The session should be stored in a cookie"
      assert_redirected_to product_type_path(assigns(:product_type))
    end
    
  test "should show product_type" do
    prod_type = product_types(:two)
    category1 = category_id_product_type_maps(:three)
    category2 = category_id_product_type_maps(:four)
    get :show, id: prod_type.to_param
    assert_not_nil assigns(:product_type)
    assert_not_nil assigns(:categories)
    assert_equal String(prod_type.id), session[:current_product_type_id], "The session should be stored in a cookie"
    assert_response :success
  end
  
  test "should get new" do
    get :new
    assert_not_nil assigns(:product_type)
    assert_response :success
  end
  
  test "should get edit" do
    get :edit, id: @product_type.to_param
    assert_not_nil assigns(:product_type)
    assert_not_nil assigns(:categories)
    assert_response :success
  end
  
  test "should create product_type" do
    assert_difference('ProductType.count') do
      @new_product_type = build(:product_type)
      post :create, :name => @new_product_type.name
    end
    assert_equal assigns(:product_type).to_param, String(session[:current_product_type_id])
    assert_response :success
    assert_template('redirecting')
  end
  
  test "error in creating product_type" do
    @new_product_type = build(:product_type)
    post :create, :name => @new_product_type.name
    assert_no_difference('ProductType.count') do
      post :create, :name => @new_product_type.name
    end
    assert_response :success
    assert_template('new')
  end
  
  test "should update product_type" do
    put :update, id: @product_type.to_param, categories: nil
    assert_equal @product_type.to_param, session[:current_product_type_id]
    assert_template('redirecting')
    assert_response :success
  end
  
  test "fail to update product_type" do
    prod_type = product_types(:two)
    categories = {"0"=>["21344", "Televisions"], "1"=>["21344", "Televisions"]}
    put :update, id: prod_type.id, categories: categories
    assert_equal assigns(:product_type).to_param, session[:current_product_type_id]
    assert_template('edit')
    assert_response :success
  end
  
  test "should destroy product_type" do
    assert_difference('ProductType.count', -1) do
      delete :destroy, id: @product_type.to_param
    end
    assert_redirected_to product_types_path
  end
end
