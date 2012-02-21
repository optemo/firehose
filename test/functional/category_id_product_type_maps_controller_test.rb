require 'test_helper'

class CategoryIdProductTypeMapsControllerTest < ActionController::TestCase
  
  test "should get new" do
    get :new, :id => '20243'
    assert_response :success
  end
  
  test "showing" do
    get :show
    assert_response :success
    assert_template('tree')
  end
  
end
