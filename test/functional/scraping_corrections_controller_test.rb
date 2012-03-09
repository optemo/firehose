require 'test_helper'

class ScrapingCorrectionsControllerTest < ActionController::TestCase
  setup do
    @scraping_correction = scraping_corrections(:one)
    @pt_id = "B20218"
  end

  test "should get new" do
    get :new, product_type_id: @pt_id
    assert_response :success
  end

  test "should create scraping_correction" do
    assert_difference('ScrapingCorrection.count') do
      post :create, product_type_id: @pt_id, :scraping_correction => @scraping_correction.attributes
    end
    assert_response :success
    #assert_redirected_to scraping_correction_path(assigns(:scraping_correction))
  end

  test "should get edit" do
    get :edit, product_type_id: @pt_id, :id => @scraping_correction.to_param
    assert_response :success
  end

  test "should update scraping_correction" do
    put :update, product_type_id: @pt_id, :id => @scraping_correction.to_param, :scraping_correction => @scraping_correction.attributes
    assert_response :success
    #assert_redirected_to scraping_correction_path(assigns(:scraping_correction))
  end

  test "should destroy scraping_correction" do
    assert_difference('ScrapingCorrection.count', -1) do
      delete :destroy, product_type_id: @pt_id, :id => @scraping_correction.to_param
    end

    #assert_redirected_to scraping_corrections_path
    assert_response :success
  end
end
