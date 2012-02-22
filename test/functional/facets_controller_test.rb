require 'test_helper'

class FacetsControllerTest < ActionController::TestCase
  setup do
    @pt_id = product_categories(:cameras).product_type
    create(:scraping_rule, rule_type: "Continuous")
    create(:scraping_rule, rule_type: "Categorical")
    create(:scraping_rule, rule_type: "Binary")
    
    @f1 = create(:facet, used_for: "filter")
    @f2 = create(:facet, used_for: "sortby")    
    @f3 = create(:facet, used_for: "show")
  end
  
  test "should show layout for the right product category" do
   get :index, product_type_id: @pt_id
   assert_template('editor')
   assert_response :success
   
   assert_not_equal [], assigns("db_filters")
   assert_not_equal [], assigns("db_sortby")
   assert_not_equal [], assigns("db_compare")
   assert_not_equal [], assigns("sr_filters")
   assert_not_equal [], assigns("sr_sortby")
   assert_not_equal [], assigns("sr_compare")
   assert_equal @pt_id, Session.product_type, "The product type should be stored in the session object"
  end
  
  test "should get default layout and sr when scraping rules for an ancestor" do
   get :index, product_type_id: "B22474"
   assert_template('editor')
   assert_response :success
      
   assert_not_equal [], assigns("db_filters")
   assert_not_equal [], assigns("db_sortby")
   assert_not_equal [], assigns("db_compare")
   assert_not_equal [], assigns("sr_filters")
   assert_not_equal [], assigns("sr_sortby")
   assert_not_equal [], assigns("sr_compare")
  end
  
   
  test "should get blank layout and scraping rules when none defined for an ancestor" do
   create(:product_category, :product_type => "B20007")
   get :index, product_type_id: "B20007"
   assert_response :success
   assert_equal [], assigns("db_filters"), "should have no facets of its own nor do its ancestors"
  end

  test "getting feature names to add from the scraping rules" do
     
     get :index, product_type_id: @pt_id
     
     filters = assigns("sr_filters")
     sortby = assigns("sr_sortby")
     compare = assigns("sr_compare")
     
     assert_equal 3, filters.length, "Should get features to add for filters from scraping rules"
     assert_equal 3, compare.length, "Should get features to add for compare from scraping rules"
     assert_equal 1, sortby.length, "Should get features to add forsortby from scraping rules"
    end
    
    test "retrieving existing facets to display" do
     f0 = create(:facet, used_for: "filter")
     
     get :index, product_type_id: @pt_id
     filters = assigns("db_filters")
     sortby = assigns("db_sortby")
     compare = assigns("db_compare")
         
     assert_equal 2, filters.length, "Should get filters values from facets in the database"
     assert_equal 1, compare.length, "Should get compare values from facets in the database"
     assert_equal 1, sortby.length, "Should get sortby values from facets in the database"
     assert_equal @f1, filters[0], "Existing filters should be same as those in the database"
     assert_equal @f2, sortby[0], "Existing sortby should be same as those in the database"
     assert_equal @f3, compare[0], "Existing compare features should be same as those in the database"
     
     f4 = create(:facet, used_for: "sortby")
     get :index, product_type_id: @pt_id
     sortby = assigns("db_sortby")
     assert_equal f4, sortby[1], "Existing sorby features should be same as those in the database"
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
     
     f4 = create(:facet, used_for: "sortby", id: 104)
     
     original_filters = Facet.find_all_by_used_for("filter")
     original_sorting = Facet.find_all_by_used_for("sortby")
     original_compare = Facet.find_all_by_used_for("show")
     post :create, request_data.merge(product_type_id: @pt_id)
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
  
    test "adding a heading to the layout" do
      get :new, product_type_id: @pt_id, type: 'Heading', used_for: 'filter'
      facet = assigns(:new_facet)
      assert_equal 'B20218', facet.product_type
      assert_equal 'Heading', facet.feature_type
      assert_equal 'filter', facet.used_for
    end
  
    test "adding a compare facet to the layout" do
      sr = create(:scraping_rule, local_featurename: "saleprice", rule_type: "Continuous")
      get :new, product_type_id: @pt_id, name: 'saleprice', used_for: 'show'
      facet = assigns(:new_facet)
      assert_equal 'B20218', facet.product_type
      assert_equal 'saleprice', facet.name
      assert_equal 'Continuous', facet.feature_type
      assert_equal 'show', facet.used_for
    end
    
    test "adding a sortby element to the layout" do
      sr = create(:scraping_rule, local_featurename: "opticalzoom", rule_type: "Continuous")
      get :new, product_type_id: @pt_id, name: 'opticalzoom', used_for: 'filter'
      facet = assigns(:new_facet)
      assert_equal 'B20218', facet.product_type
      assert_equal 'Continuous', facet.feature_type
      assert_equal 'filter', facet.used_for
    end

end
