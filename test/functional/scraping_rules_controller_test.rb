require 'test_helper'

class ScrapingRulesControllerTest < ActionController::TestCase
  setup do
    @scraping_rule = create(:scraping_rule)
  end

  test "should get new" do
    get :new, :rule => {remote_featurename: "Name"}
    assert_response :success
  end

  test "should create scraping_rule" do
    assert_difference('ScrapingRule.count') do
      @scraping_rule.id = 3
      post :create, :scraping_rule => @scraping_rule.attributes
    end

    assert_redirected_to root_url
  end

  test "should get edit" do
    get :edit, :id => @scraping_rule.to_param
    assert_response :success
  end

  test "should update scraping_rule" do
    put :update, :id => @scraping_rule.to_param, :scraping_rule => @scraping_rule.attributes
    assert_redirected_to root_url
  end

  test "should destroy scraping_rule" do
    assert_difference('ScrapingRule.count', -1) do
      delete :destroy, :id => @scraping_rule.to_param
    end

    assert_redirected_to root_url
  end
end
