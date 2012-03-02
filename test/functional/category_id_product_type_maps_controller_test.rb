require 'test_helper'

class CategoryIdProductTypeMapsControllerTest < ActionController::TestCase
  setup do
    @pt_id = product_categories(:cameras).product_type
  end
  
  test "should get new" do
    get :new, :id => '20243', product_type_id: @pt_id
    assert_response :success
  end
  
  test "showing" do
    get :show, :id => '20243', product_type_id: @pt_id
    assert_response :success
    assert_template('tree')
  end
  
end