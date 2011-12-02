require 'test_helper'

class ProductTest < ActiveSupport::TestCase
  
  setup do
    Session.new
  end
  
  test "product caching" do
    product1 = create(:product)
    product2 = create(:product)
    retrieved_product = Product.cached(product1.id)
    retrieved_all_products = Product.manycached([product1.id, product2.id])

    assert_equal product1, retrieved_product, "retrieved product not the same as original"
    assert_not_nil retrieved_all_products.index(product1), "could not find project in cache"
    assert_not_nil retrieved_all_products.index(product2), "could not find project in cache"
  end
  
  test "calculating factors" do
    
    CategoricalFacetValue.create(:id => 2, :facet_id => 6, :name => "Canon", :value => 1)
        
    Product.calculate_factors
    
    pid = products(:oneproduct).id
    
    # check that factors were computed for the product for the 
    saleprice_spec = ContSpec.find_by_product_id_and_name(pid, 'saleprice_factor')
    opticalzoom_spec = ContSpec.find_by_product_id_and_name(pid, 'opticalzoom_factor')
    featured_spec = ContSpec.find_by_product_id_and_name(pid, 'featured_factor')
    maxresolution_spec = ContSpec.find_by_product_id_and_name(pid, 'maxresolution_factor')
    brand_spec = ContSpec.find_by_product_id_and_name(pid, 'brand_factor')
    onsale_spec = ContSpec.find_by_product_id_and_name(pid, 'onsale_factor')
    rating_spec = ContSpec.find_by_product_id_and_name(pid, 'customerRating_factor')
    utility_spec = ContSpec.find_by_product_id_and_name(pid, 'utility')
        
    # check that that the specs and utility values are not nil for that product
    assert_not_nil saleprice_spec
    assert_not_nil opticalzoom_spec
    assert_not_nil featured_spec
    assert_not_nil maxresolution_spec
    assert_not_nil brand_spec
    assert_not_nil onsale_spec
    assert_not_nil utility_spec
    assert_not_nil rating_spec
    
    # check that values are as expected
    # TODO: check the values for the other factors as well, computed with more than one product
    assert_in_delta utility_spec.value, 0.175172, 0.000001
    assert_in_delta rating_spec.value, 0.0, 0.000001
    
  end
  
  test "rating factor calculation" do
    #Should have a star rating cutoff of >= 4
    rating1 = 0.0
    assert_equal 0, Product.calculateFactor_rating(rating1)
    rating2 = 4.0                                          
    assert_equal 1, Product.calculateFactor_rating(rating2)
    rating3 = 5.0                                          
    assert_equal 1, Product.calculateFactor_rating(rating3)
  end 
  
  test "Product and Spec import from BBY API" do
    sr = create(:scraping_rule, local_featurename: "longDescription", remote_featurename: "longDescription")
    Product.feed_update
    #20 created(Current BB page size), and 1 in the fixtures
    assert_equal 21, Product.count, "There should be 10 products created in the database"
    assert_equal true, Product.all.map(&:instock).inject(true){|res,el|res && el}, "All products should be instock"
    assert_equal ["longDescription"]*20, Product.all[1..-1].map{|p|p.cat_specs.first.name}, "Test that the longDescription is available"
  end
  
  test "Get Rules" do
    sr = create(:scraping_rule, local_featurename: "longDescription", remote_featurename: "longDescription")
    myrules = ScrapingRule.get_rules([],false)
    assert_equal sr, myrules.first[:rule], "Get Rules should return the singular rules in this case"
  end
end
