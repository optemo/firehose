require 'test_helper'

class ScrapingRulesControllerTest < ActionController::TestCase
  setup do
    @scraping_rule = create(:scraping_rule)
    @pt_id = "B20218"
  end

  test "should get new" do
    get :new, product_type_id: @pt_id, rule: {remote_featurename: "Name"}
    assert_response :success
  end
  
  test "should get rule candidates" do
    get :show, product_type_id: @pt_id, id: @scraping_rule.id
    assert_response :success
  end
  
  #test "should get multi-rules" do
  #  sr = create(:scraping_rule)
  #  c1 = build(:candidate, scraping_rule: sr)
  #  c2 = build(:candidate, scraping_rule: @scraping_rule)
  #  get :show, product_type_id: @pt_id, id: [@scraping_rule.id,sr.id].join("-")
  #  assert_response :success
  #  #Check the colors
  #  assert_equal ["#4F3333","green"], assigns[:colors].values, "Color coding isn't right"
  #  assert_equal 10, assigns[:candidates].length
  #end

  test "should create scraping_rule" do
    assert_difference('ScrapingRule.count') do
      @scraping_rule.id = 3
      post :create, product_type_id: @pt_id, scraping_rule: @scraping_rule.attributes
    end
    assert_response :success
  end

  test "should get edit" do
    get :edit, product_type_id: @pt_id, id: @scraping_rule.to_param
    assert_response :success
  end

  test "should update scraping_rule" do
    put :update, product_type_id: @pt_id, id: @scraping_rule.to_param, scraping_rule: @scraping_rule.attributes
    assert_response :success
  end

  test "should destroy scraping_rule" do
    assert_difference('ScrapingRule.count', -1) do
      delete :destroy, product_type_id: @pt_id, id: @scraping_rule.to_param
    end
    assert_response :success
  end
end
