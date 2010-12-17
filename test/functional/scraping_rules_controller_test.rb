require 'test_helper'

class ScrapingRulesControllerTest < ActionController::TestCase
  setup do
    @scraping_rule = scraping_rules(:one)
  end

  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:scraping_rules)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create scraping_rule" do
    assert_difference('ScrapingRule.count') do
      post :create, :scraping_rule => @scraping_rule.attributes
    end

    assert_redirected_to scraping_rule_path(assigns(:scraping_rule))
  end

  test "should show scraping_rule" do
    get :show, :id => @scraping_rule.to_param
    assert_response :success
  end

  test "should get edit" do
    get :edit, :id => @scraping_rule.to_param
    assert_response :success
  end

  test "should update scraping_rule" do
    put :update, :id => @scraping_rule.to_param, :scraping_rule => @scraping_rule.attributes
    assert_redirected_to scraping_rule_path(assigns(:scraping_rule))
  end

  test "should destroy scraping_rule" do
    assert_difference('ScrapingRule.count', -1) do
      delete :destroy, :id => @scraping_rule.to_param
    end

    assert_redirected_to scraping_rules_path
  end
end
