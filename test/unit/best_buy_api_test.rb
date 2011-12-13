require 'test_helper'

class ScrapingCorrectionTest < ActiveSupport::TestCase
  # Replace this with your real tests.

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
 
  test "get subcategories" do  
    subcats = BestBuyApi.get_subcategories(id= 20243, english = true)
    puts "#{subcats}"
    keys = subcats.keys
    assert_equal(3, subcats.values_at("20243"=> keys[0].values_at("20243")[0])[0].to_a.length, "there should be 3 subcategories for 'the USB Flash Drivers' category")
  end
 
  test "keyword search" do
    skus = BestBuyApi.keyword_search ("Camera")
    puts "#{skus.size}"
    assert_equal(skus.size, skus.uniq.size,"there is no duplicate in skus")
  end
  
end
