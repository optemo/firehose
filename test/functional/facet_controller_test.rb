require 'test_helper'

class FacetControllerTest < ActionController::TestCase
  setup do
    Session.new 2
  end
  
  test "should get new" do
    get :new
    assert_response :success
    assert_template('new') 
  end

  test "adding a heading to the layout" do
    get :new, type: 'Heading', used_for: 'filter'
    facet = assigns(:new_facet)
    assert_equal 2, facet.product_type_id
    assert_equal 'Heading', facet.feature_type
    assert_equal 'filter', facet.used_for
  end

  test "adding a compare facet to the layout" do
    sr = create(:scraping_rule, local_featurename: "saleprice", rule_type: "cont")
    get :new, name: 'saleprice', used_for: 'show'
    facet = assigns(:new_facet)
    assert_equal 2, facet.product_type_id
    assert_equal 'saleprice', facet.name
    assert_equal 'Continuous', facet.feature_type
    assert_equal 'show', facet.used_for
  end
  
  test "adding a sortby element to the layout" do
    sr = create(:scraping_rule, local_featurename: "opticalzoom", rule_type: "cont")
    get :new, name: 'opticalzoom', used_for: 'filter'
    facet = assigns(:new_facet)
    assert_equal 2, facet.product_type_id
    assert_equal 'Continuous', facet.feature_type
    assert_equal 'filter', facet.used_for
  end

end
