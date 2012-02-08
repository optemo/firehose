require 'test_helper'

class LayoutEditorControllerTest < ActionController::TestCase
  
  test 'index should redirect to show' do
    get :index
    assert_redirected_to(layout_editor_path(Session.product_type_id))
  end
  
  test 'change locale' do
    get :index, :locale => :en
    assert_equal :en, I18n.locale
    get :index, :locale => :fr
    assert_equal :fr, I18n.locale
  end
  
  test "should show layout for the right product_type" do
    # make scraping rules
    prod_type = product_types(:one)
    get :show, id: prod_type.id
    assert_template('show')
    assert_response :success
    
    assert_not_nil assigns("db_filters")
    assert_not_nil assigns("db_sortby")
    assert_not_nil assigns("db_compare")
    assert_not_nil assigns("sr_filters")
    assert_not_nil assigns("sr_sortby")
    assert_not_nil assigns("sr_compare")
    assert_equal prod_type.id, session[:current_product_type_id], "The session should be stored in a cookie"
    assert_equal prod_type.id, Session.product_type_id, "The product type should be stored in the session object"
  end
  
  test "getting feature names to add from the scraping rules" do
    prod_type = product_types(:one)
    
    sr1 = create(:scraping_rule, rule_type: "Continuous")
    sr2 = create(:scraping_rule, rule_type: "Categorical")
    sr3 = create(:scraping_rule, rule_type: "Binary")
    
    get :show, id: prod_type.id
    
    filters = assigns("sr_filters")
    sortby = assigns("sr_sortby")
    compare = assigns("sr_compare")
    
    assert_equal 3, filters.length, "Should get features to add for filters from scraping rules"
    assert_equal 3, compare.length, "Should get features to add for compare from scraping rules"
    assert_equal 1, sortby.length, "Should get features to add forsortby from scraping rules"
  end
  
  test "retrieving existing facets to display" do
    f1 = create(:facet, used_for: "filter")
    f2 = create(:facet, used_for: "filter")
    f3 = create(:facet, used_for: "show")
    
    get :show, id: f1.product_type_id
    filters = assigns("db_filters")
    sortby = assigns("db_sortby")
    compare = assigns("db_compare")
        
    assert_equal 2, filters.length, "Should get filters values from facets in the database"
    assert_equal 1, compare.length, "Should get compare values from facets in the database"
    assert_equal 0, sortby.length, "Should get sortby values from facets in the database"
    assert_equal f1, filters[0], "Existing filters should be same as those in the database"
    assert_equal f2, filters[1], "Existing filters should be same as those in the database"
    assert_equal f3, compare[0], "Existing compare features should be same as those in the database"
    
    f4 = create(:facet, used_for: "sortby")
    get :show, id: f1.product_type_id
    sortby = assigns("db_sortby")
    assert_equal f4, sortby[0], "Existing sorby features should be same as those in the database"
  end
  
  test "saving a new layout" do
    request_data = {"id" => 2,
      "filter_set"=>
      {"0"=>["Binary", "toprated", "Top Rated", "stars", "boldlabel"],
       "1"=>["Heading", "status", "Status", "", ""],
       },
     "sorting_set"=>
      {"0"=>["Continuous", "displayDate", "displayDate", "", "asc"],
       "1"=>["Continuous", "saleprice", "Sale Price", "$", "asc"],
       "2"=>["Continuous", "orders", "orders", "", "asc"]},
     "compare_set"=>
      {"0"=>["Categorical", "color", "color", "", ""]}
     }
    
    f1 = create(:facet, used_for: "filter")
    f2 = create(:facet, used_for: "filter")
    f3 = create(:facet, used_for: "show")
    f3 = create(:facet, used_for: "sortby") 
    
    original_filters = Facet.find_all_by_used_for("filter")
    original_sorting = Facet.find_all_by_used_for("sortby")
    original_compare = Facet.find_all_by_used_for("show")
    post :create, request_data
    assert_response :success
    assert_template(nil)
    
    updated_filters = Facet.find_all_by_used_for("filter")
    updated_sorting = Facet.find_all_by_used_for("sortby")
    updated_compare = Facet.find_all_by_used_for("show")
    
    assert_not_equal original_filters.first, updated_filters.first, "filter facets should be different"
    assert_not_equal original_sorting.first, updated_sorting.first, "sorting facets should be different"
    assert_not_equal original_compare.first, updated_compare.first, "compare facets should be different"
    
    assert_nil Facet.find_by_id_and_name(original_filters.first.id, original_filters.first.name), 
      "a facet formerly in the database but not in the layout should be removed"
    assert_nil Facet.find_by_id_and_name(original_sorting.first.id, original_sorting.first.name), 
      "a facet formerly in the database but not in the layout should be removed"
    assert_nil Facet.find_by_id_and_name(original_compare.first.id, original_compare.first.name), 
      "a facet formerly in the database but not in the layout should be removed"
    assert_not_nil Facet.find_by_name_and_used_for('saleprice','sortby'), "newly added facet should be in the database"
  end
end
