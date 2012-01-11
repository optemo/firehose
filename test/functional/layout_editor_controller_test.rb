require 'test_helper'

class LayoutEditorControllerTest < ActionController::TestCase
  # test "the truth" do
  #   assert true
  # end
  
  test "should show layout for the right product_type" do
    
    # make scraping rules
    prod_type = product_types(:one)
    sr1 = create(:scraping_rule)
    sr2 = create(:scraping_rule)
    sr3 = create(:scraping_rule)
    
    get :show, id: prod_type.id
    assert_not_nil assigns(@db_filters)
    assert_not_nil assigns(@db_sortby)
    assert_not_nil assigns(@db_compare)
    assert_not_nil assigns(@sr_filters)
    assert_not_nil assigns(@sr_sortby)
    assert_not_nil assigns(@sr_compare)
    #to do: check that the lists of filters etc selected here are as expected
    assert_equal prod_type.id, session[:current_product_type_id], "The session should be stored in a cookie"
    assert_equal prod_type.id, Session.product_type_id, "The product type should be stored in the session object"
    assert_response :success
  end
  
  test "retrieving existing facets to display" do
    f1 = create(:facet, used_for: "filter")
    f2 = create(:facet, used_for: "filter")
    f3 = create(:facet, used_for: "show")
    
    get :show, id: f1.product_type_id
    filters = assigns(@db_filters)
    sortby = assigns(@db_sortby)
    compare = assigns(@db_compare)
    
    debugger
    
    assert_equal 2, @db_filters
    
    # make a couple of facets: Continuous / Categorical / Binary;
    # used_for: show / filter / sortby
    # then get :show on the page, and check that the @db_filters, @db_sortby, @db_compare have the list of
    # ?? that is expected
    assert true
  end
  
end
