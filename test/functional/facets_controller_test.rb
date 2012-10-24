require 'test_helper'

class FacetsControllerTest < ActionController::TestCase
  setup do
    @pt_id = product_categories(:cameras).product_type
    @cont_sr = create(:scraping_rule, rule_type: "Continuous")
    @cat_sr = create(:scraping_rule, rule_type: "Categorical")
    @bin_sr = create(:scraping_rule, rule_type: "Binary")
    
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
     # Possible addition: also test the features from applicable CUSTOM rules being in the filters
     f4 = create(:facet, feature_type: "Ordering", used_for: @cat_sr.local_featurename)
     
     get :index, product_type_id: @pt_id
     
     filters = assigns("sr_filters")
     sortby = assigns("sr_sortby")
     compare = assigns("sr_compare")
     categories_with_order = assigns("categories_with_order")
     assert filters.include?(@bin_sr.local_featurename), "Should get features to add for filters from scraping rules"
     assert sortby.include?(@cont_sr.local_featurename), "Should get features to add for compare from scraping rules"
     assert compare.include?(@cat_sr.local_featurename), "Should get features to add forsortby from scraping rules"
     assert categories_with_order.include?(f4.used_for)
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
  
  test "getting the edit category ordering" do
    request_data = {"action"=>"edit",
     "controller"=>"facets",
     "product_type_id"=>"B20218",
     "id"=>"driveSize"}
    driveSize_sr = create(:scraping_rule, rule_type: "Categorical", local_featurename: 'driveSize')
    spec1 = create(:cat_spec, product_id: 889, name: 'product_type', value: 'B22474')
    spec2 = create(:cat_spec, product_id: 889, name: 'driveSize', value: '2.5')
    
    get :edit, request_data
    assert_response :success
    categories = assigns(:categories)
    facet_name = assigns(:facet_name)
    product_type = assigns(:product_type)
    
    assert_not_nil categories
    assert_equal spec2.value, categories[0]
    assert_equal 'driveSize', facet_name
    assert_equal 'B20218', product_type
  end
  
  test "creating and resetting a layout" do
    request_data = {"filter_set"=>
      {"0"=>["", "Binary", "toprated", "Top Rated", "stars", "true", "false"],
       "1"=>["", "Heading", "Heading", "Status", "Status", "false", "false"],
       "2"=>["", "Categorical", "product_type", "Product Category", "", "true", "false", "B20222", "B24394", "B30118"]},
     "sorting_set"=>
      {"0"=>["104", "Categorical", "displayDate", "displayDate", "", "asc", "false"],
       "1"=>["", "Continuous", "saleprice", "saleprice", "", "asc", "false"],
       "2"=>["", "Continuous", "utility", "utility", "", "desc", "false"]},
     "compare_set"=>
      {"0"=>["", "Categorical", "color", "color", "", "false", "false"]},
     "action"=>"create",
     "controller"=>"facets",
     "product_type_id"=>"B20218"}

    f4 = create(:facet, used_for: "sortby", id: 104)

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

    # facet set saved
    assert_nil Facet.find_by_id_and_name(original_filters.first.id, original_filters.first.name), 
     "a facet formerly in the database but not in the layout should be removed"
    assert_nil Facet.find_by_id_and_name(original_sorting.first.id, original_sorting.first.name), 
     "a facet formerly in the database but not in the layout should be removed"
    assert_nil Facet.find_by_id_and_name(original_compare.first.id, original_compare.first.name), 
     "a facet formerly in the database but not in the layout should be removed"
    # translations saved
    assert_equal "Top Rated", I18n.t("B20218.filter.toprated.name"), 'should save translation for facet name'
    assert_equal "stars", I18n.t("B20218.filter.toprated.unit"), 'should save translation for facet unit'
    # order saved
    assert Facet.find_by_feature_type_and_name('Ordering',"B20222").value < Facet.find_by_feature_type_and_name('Ordering',"B24394").value, "wrong ordering"
    assert Facet.find_by_feature_type_and_name('Ordering',"B24394").value < Facet.find_by_feature_type_and_name('Ordering',"B30118").value, "wrong ordering"

    # changing the ordering
    request_data['filter_set']['2'] = ["", "Categorical", "product_type", "Product Category", "", "true", "false", "B30118", "B24394"]
    post :create, request_data
    assert_response :success
    assert_nil Facet.find_by_feature_type_and_name('Ordering',"B20222"), "wrong ordering"
    assert Facet.find_by_feature_type_and_name('Ordering',"B30118").value < Facet.find_by_feature_type_and_name('Ordering',"B24394").value, "wrong ordering"
    
    # resetting the layout
    request_data["filter_set"] = "null"
    request_data["sorting_set"] = "null"
    request_data["compare_set"] = "null"
    post :create, request_data
    assert_response :success
    assert_empty Facet.find_all_by_used_for("filter"), 'facets deleted on reset'
    assert_empty Facet.find_all_by_used_for("sortby"), 'facets deleted on reset'
    assert_empty Facet.find_all_by_used_for("show"), 'facets deleted on reset'
    assert_empty Facet.find_all_by_feature_type("Ordering"), 'facets deleted on reset'
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
