require 'test_helper'

class ScrapingControllerTest < ActionController::TestCase
  setup do
    #Session.new #Sets up a default camera_bestbuy session
  end
  test "should get index" do
    get :index
    assert_response :success
  end

  test "should get scrape for digital elph" do
    get :scrape, id: "10164411"
    assert_response :success
  end
  
  test "should get rules" do
    get :rules
    assert_response :success
  end
  
  test "should get datafeed" do
    get :datafeed
    assert_response :success
  end

end
