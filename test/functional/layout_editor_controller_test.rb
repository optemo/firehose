require 'test_helper'

class LayoutEditorControllerTest < ActionController::TestCase
  
  test 'index should redirect to show' do
   get :index
   assert_redirected_to(layout_editor_path(Session.product_type))
  end
  
  test 'change locale' do
   get :index, :locale => :en
   assert_equal :en, I18n.locale
   get :index, :locale => :fr
   assert_equal :fr, I18n.locale
  end
  
  test "should show layout for the right product category" do
   # make scraping rules
   prod_type = product_categories(:cameras).product_type
   get :show, id: prod_type
   assert_template('show')
   assert_response :success
   
   assert_not_nil assigns("db_filters")
   assert_not_nil assigns("db_sortby")
   assert_not_nil assigns("db_compare")
   assert_not_nil assigns("sr_filters")
   assert_not_nil assigns("sr_sortby")
   assert_not_nil assigns("sr_compare")
   assert_equal prod_type, session[:current_product_type], "The session should be stored in a cookie"
   assert_equal prod_type, Session.product_type, "The product type should be stored in the session object"
  end
  
  test "getting feature names to add from the scraping rules" do
   
   sr1 = create(:scraping_rule, rule_type: "Continuous")
   sr2 = create(:scraping_rule, rule_type: "Categorical")
   sr3 = create(:scraping_rule, rule_type: "Binary")
   
   prod_type = sr1.product_type
   
   get :show, id: prod_type
   
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
   
   get :show, id: f1.product_type
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
   get :show, id: f1.product_type
   sortby = assigns("db_sortby")
   assert_equal f4, sortby[0], "Existing sorby features should be same as those in the database"
  end
  
  test "saving a new layout" do
   request_data = {"id" => "B20218",
     "filter_set"=>
     {"0"=>["100", "Binary", "toprated", "Top Rated", "stars", "boldlabel"],
      "1"=>["101", "Heading", "status", "Status", "", ""],
      },
    "sorting_set"=>
     {"0"=>["102", "Continuous", "displayDate", "displayDate", "", "asc"],
      "1"=>["103", "Continuous", "saleprice", "Sale Price", "$", "asc"],
      "2"=>["104", "Continuous", "orders", "orders", "", "asc"]},
    "compare_set"=>
     {"0"=>["105", "Categorical", "color", "color", "", ""]}
    }
   
   f1 = create(:facet, used_for: "filter")
   f2 = create(:facet, used_for: "filter")
   f3 = create(:facet, used_for: "show")
   f3 = create(:facet, used_for: "sortby", id: 104)
   
   original_filters = Facet.find_all_by_used_for("filter")
   original_sorting = Facet.find_all_by_used_for("sortby")
   original_compare = Facet.find_all_by_used_for("show")
   post :create, request_data
   assert_response :success
   assert_template(nil)
   
   updated_filters = Facet.find_all_by_used_for("filter")
   updated_sorting = Facet.find_all_by_used_for("sortby")
   updated_compare = Facet.find_all_by_used_for("show")
   
   assert_not_equal original_filters.first, updated_filters.first, "filter facet set should be updated"
   assert_not_equal original_sorting.count, updated_sorting.count, "sorting facet set should be updated"
   assert_not_equal original_compare.first, updated_compare.first, "compare facet set should be updated"
   
   assert_not_nil Facet.find_by_name_and_used_for('saleprice','sortby'), "newly added facet should be in the database"
   assert_equal "asc", Facet.find(104).style, "existing facet should be updated"
   
   assert_nil Facet.find_by_id_and_name(original_filters.first.id, original_filters.first.name), 
     "a facet formerly in the database but not in the layout should be removed"
   assert_nil Facet.find_by_id_and_name(original_sorting.first.id, original_sorting.first.name), 
     "a facet formerly in the database but not in the layout should be removed"
   assert_nil Facet.find_by_id_and_name(original_compare.first.id, original_compare.first.name), 
     "a facet formerly in the database but not in the layout should be removed"
   
   assert_equal "Top Rated", I18n.t("B20218.filter.toprated.name"), 'should save translation for facet name'
   assert_equal "stars", I18n.t("B20218.filter.toprated.unit"), 'should save translation for facet unit'
  end
end
