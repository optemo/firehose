require 'test_helper'

class ScrapingRulesControllerTest < ActionController::TestCase
  setup do
    @scraping_rule = create(:scraping_rule)
  end

  test "should get new" do
    get :new, :rule => {remote_featurename: "Name"}
    assert_response :success
  end
  
  test "should get rule candidates" do
    get :show, id: @scraping_rule.id
    assert_response :success
  end
  
  test "should get multi-rules" do
    sr = create(:scraping_rule)
    c1 = build(:candidate, scraping_rule: sr)
    c2 = build(:candidate, scraping_rule: @scraping_rule)
    get :show, id: [@scraping_rule.id,sr.id].join("-")
    assert_response :success
    #Check the colors
    assert_equal ["#4F3333","green"], assigns[:colors].values, "Color coding isn't right"
    assert_equal 10, assigns[:candidates].length
  end

  test "should create scraping_rule" do
    assert_difference('ScrapingRule.count') do
      @scraping_rule.id = 3
      post :create, :scraping_rule => @scraping_rule.attributes
    end
    assert_redirected_to rules_url
  end

  test "should get edit" do
    get :edit, :id => @scraping_rule.to_param
    assert_response :success
  end

  test "should update scraping_rule" do
    put :update, :id => @scraping_rule.to_param, :scraping_rule => @scraping_rule.attributes
    assert_redirected_to rules_url
  end

  test "should destroy scraping_rule" do
    assert_difference('ScrapingRule.count', -1) do
      delete :destroy, :id => @scraping_rule.to_param
    end
    debugger
    assert_redirected_to rules_url
  end
end
