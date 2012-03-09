require 'test_helper'

class BBproductsControllerTest < ActionController::TestCase
  setup do
    @sr = create(:scraping_rule, local_featurename: "hophead")
    @sr_drive = create(:scraping_rule, product_type: "B20243")
  end
  test "should get index" do
    get :index, product_type_id: "B20218"
    assert_response :success
  end
  
  test "Change current product type" do
    post :index, product_type_id: "B20218"
    assert_equal Session.product_type, "B20218", "The Session object should be set"
  end

  test "should get scrape for digital elph" do
    get :show, product_type_id: "B20243", id: "10164411"
    assert_response :success
  end

end
