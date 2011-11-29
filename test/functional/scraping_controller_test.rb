require 'test_helper'

class ScrapingControllerTest < ActionController::TestCase
  setup do
    @sr = create(:scraping_rule, local_featurename: "hophead")
    @sr_drive = create(:scraping_rule, product_type: "drive_bestbuy")
  end
  test "should get index" do
    get :index
    assert_response :success
  end
  
  test "Change current product type" do
    post :index, :product_type => {id: 6}
    assert_equal Session.product_type, "drive_bestbuy", "The Session object should be set"
    get :index
    assert session[:current_product_type_id], "The session should be stored in a cookie"
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
  
  test "only the current rules should be displayed" do
    get :myrules
    assert_response :success
    assert_equal assigns[:rules], [@sr].group_by(&:local_featurename), "Our scraping rules should be returned" 
  end
end
