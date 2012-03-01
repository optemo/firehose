require 'test_helper'

class CategoryIdProductTypeMapsControllerTest < ActionController::TestCase
  
  test "should get new" do
    get :new, :product_type_id => "B20218", :id => '20243'
    assert_response :success
  end
  
  test "showing" do
    get :show, :product_type_id => "B20218"
    assert_response :success
    assert_template('tree')
  end
  
end