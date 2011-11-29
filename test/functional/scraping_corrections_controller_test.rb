require 'test_helper'

class ScrapingCorrectionsControllerTest < ActionController::TestCase
  setup do
    @scraping_correction = scraping_corrections(:one)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create scraping_correction" do
    assert_difference('ScrapingCorrection.count') do
      post :create, :scraping_correction => @scraping_correction.attributes
    end
    assert_response :success
    #assert_redirected_to scraping_correction_path(assigns(:scraping_correction))
  end

  test "should get edit" do
    get :edit, :id => @scraping_correction.to_param
    assert_response :success
  end

  test "should update scraping_correction" do
    put :update, :id => @scraping_correction.to_param, :scraping_correction => @scraping_correction.attributes
    assert_response :success
    #assert_redirected_to scraping_correction_path(assigns(:scraping_correction))
  end

  test "should destroy scraping_correction" do
    assert_difference('ScrapingCorrection.count', -1) do
      delete :destroy, :id => @scraping_correction.to_param
    end

    #assert_redirected_to scraping_corrections_path
    assert_response :success
  end
end
