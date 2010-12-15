require 'test_helper'

class ScrapingControllerTest < ActionController::TestCase
  test "should get index" do
    get :index
    assert_response :success
  end

  test "should get scrape" do
    get :scrape
    assert_response :success
  end

end
