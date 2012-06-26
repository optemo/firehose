require 'test_helper'

class ScrapingCorrectionTest < ActiveSupport::TestCase
  setup do
    # set the session department to a bestbuy department for the API calls to the BestBuy API
    Session.new 'BDepartments'
  end
  
  test "Best buy API" do
    assert( BestBuyApi.product_search(id = 28381, includeall = false, english = true))
    assert BestBuyApi.listing (21344)
  end   
  test "get some ids" do
     ids= BestBuyApi.some_ids(id = 28381)
     res = ids.inject([]){|res,ele| res << ele.id unless res.include?(ele.id)}
     assert_equal(ids.size, res.size,"there is no duplicate in skus")
     
     ids = BestBuyApi.some_ids([30442,28381])
     res = ids.inject([]){|res,ele| res << ele.id unless res.include?(ele.id)}
     assert_equal(ids.size, res.size,"there is no duplicate in skus")
     #assert BestBuyApi.search("camera")
  end
  
  test "get fewer ids" do
    ids= BestBuyApi.some_ids(id = 28381,5)
    assert_equal(5, ids.size, "We should be able to specify the number of results")
  end
  
  test "some ids should work with product_type too" do
    ids= BestBuyApi.some_ids(id = "B28381",5)
    assert_equal(5, ids.size, "Some_ids should accept product type")
  end
  
  test "category ids should work with product_type too" do
    ids= BestBuyApi.category_ids(id = "B28381")
    assert(!ids.empty?, "Category ids should accept product type")
  end
   
  test "get subcategories" do  
    subcats = BestBuyApi.get_subcategories(id= 20243, english = true)
    keys = subcats.keys
    assert_equal(3, subcats.values_at("20243"=> keys[0].values_at("20243")[0])[0].to_a.length, "there should be 3 subcategories for 'the USB Flash Drivers' category")
  end
   
  test "keyword search" do
    skus = BestBuyApi.keyword_search ("Camera")
    assert_equal(skus.size, skus.uniq.size,"there is no duplicate in skus")
  end
  
  test "getting product ids matching a filter" do
    Session.new 'F1002' # For the API calls to use the Future Shop API
    usage_type_node = '1002'
    filter_name = "Usage Type"
    filter_value = "Ultrabook"
    all_results = {}
    BestBuyApi.get_filter_values(usage_type_node, filter_name).each { |value| all_results[value] = BestBuyApi.search_with_filter(usage_type_node, filter_name, value) }
    results_ultrabooks = all_results[filter_value]
    assert_not_equal results_ultrabooks.length, 0
  end
  
end
