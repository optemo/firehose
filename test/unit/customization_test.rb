require 'test_helper'

class CustomizationTest < ActiveSupport::TestCase
  
  setup do
    Session.new # select one product type?
  end
  
  test "get needed features" do
    features = []
    
    #Customization.get_needed_features(features)
  end
  
  test "compute specs" do
    skus = []
    
    #Customization.compute_specs(skus)
  end
  
  test "Coming Soon Rule" do
    # preorder date < today : false
    preorderDate = Date.today - 1
    result = RuleComingSoon.compute_feature([preorderDate.to_s], pid = 999)
    result.save unless result.nil?
    saved_spec = BinSpec.find_by_product_id_and_name(999, RuleComingSoon.feature_name)
    assert_nil saved_spec, 'BinSpec should not be present for false rule value'
    
    # preorder date = today : false
    preorderDate = Date.today
    result = RuleComingSoon.compute_feature([preorderDate.to_s], pid = 999)
    result.save unless result.nil?
    saved_spec = BinSpec.find_by_product_id_and_name(999, RuleComingSoon.feature_name)
    assert_nil saved_spec, 'BinSpec should not be present for false rule value'
    
    # preorder date > today : true
    preorderDate = Date.today + 1
    result = RuleComingSoon.compute_feature([preorderDate.to_s], pid = 999)
    result.save unless result.nil?
    saved_spec = BinSpec.find_by_product_id_and_name(999, RuleComingSoon.feature_name)
    assert_not_nil saved_spec, 'BinSpec should be saved for product that is new'
    assert saved_spec.value, 'BinSpec value should be true'
    
    # test invalid preorder date : catch exception thrown
    preorderDate = "2010-10-00"
    assert_raise(ArgumentError) { RuleComingSoon.compute_feature([preorderDate.to_s], pid = 999) }
  end
  
  test "Rule On Sale" do
    # saleEndDate was not present or past (i.e. product didn't have an onsale spec),
    # is now has saleEndDate set to future date -> onSale
    assert_nil BinSpec.find_by_product_id_and_name(911, RuleOnSale.feature_name)
    saleEndDate = Date.today + 1
    result = RuleOnSale.compute_feature([saleEndDate.to_s], pid = 911)
    result.save unless result.nil?
    saved_spec = BinSpec.find_by_product_id_and_name(911, RuleOnSale.feature_name)
    assert_not_nil saved_spec, 'BinSpec should be saved for true condition'
    assert saved_spec.value, 'BinSpec value should be true'
    
    # saleEndDate was present / future and is now set to today -> onSale [FIXME: check that this is right]
    old_spec = BinSpec.find_by_product_id_and_name(911, RuleOnSale.feature_name)
    assert_not_nil old_spec, 'prerequisite for test'
    saleEndDate = Date.today
    result = RuleOnSale.compute_feature([saleEndDate.to_s], pid = 911)
    result.save unless result.nil?
    saved_spec = BinSpec.find_by_product_id_and_name(911, RuleOnSale.feature_name)
    assert_not_nil saved_spec, 'BinSpec should be saved for true condition'
    assert saved_spec.value, 'BinSpec value should be true'
    
    # onsale was true, now sale end date in the past -> not on sale
    old_spec = BinSpec.find_by_product_id_and_name(911, RuleOnSale.feature_name)
    assert_not_nil old_spec, 'prerequisite for test'
    saleEndDate = Date.today - 1
    result = RuleOnSale.compute_feature([saleEndDate.to_s], pid = 911)
    result.save unless result.nil?
    saved_spec = BinSpec.find_by_product_id_and_name(911, RuleOnSale.feature_name)
    assert_nil saved_spec, 'BinSpec should not be present for false rule value'    
    
    # no saleEndDate -> not on sale
    result = RuleOnSale.compute_feature([nil], pid = 911)
    result.save unless result.nil?
    saved_spec = BinSpec.find_by_product_id_and_name(911, RuleOnSale.feature_name)
    assert_nil saved_spec, 'BinSpec should not be present for false rule value'
    
    saleEndDate = "2010-10-00"
    assert_raise(ArgumentError) { RuleOnSale.compute_feature([saleEndDate.to_s], pid = 911) }
  end
  
  test "Rule New" do
    # inputs:
    # displayDate > 30days ago, < today AND preorderDate = 30 days ago
    displayDate = Date.today - 29
    preorderDate = Date.today - 30
    result = RuleNew.compute_feature([displayDate.to_s, preorderDate.to_s], pid = 999)
    result.save unless result.nil?
    
    saved_spec = BinSpec.find_by_product_id_and_name(999, RuleNew.feature_name)
    assert_not_nil saved_spec, 'BinSpec should be saved for product that is new'
    assert saved_spec.value, 'BinSpec value for new product should be 1'
    
    # displayDate < 30days ago, no preorderDate
    displayDate = Date.today - 31
    result = RuleNew.compute_feature([displayDate.to_s, nil], pid = 999)
    result.save unless result.nil?
    # check that there was a binspec saved
    saved_spec = BinSpec.find_by_product_id_and_name(999, RuleNew.feature_name)
    assert_nil saved_spec, 'BinSpec for new should not be present for product that is not new'
    
    # preorderDate = 31 days ago, no displayDate
    preorderDate = Date.today - 31
    result = RuleNew.compute_feature([nil, preorderDate.to_s], pid = 999)
    result.save unless result.nil?
    saved_spec = BinSpec.find_by_product_id_and_name(999, RuleNew.feature_name)
    assert_nil saved_spec, 'BinSpec for new should not be present for product that is not new'
    
    # displayDate = today
    displayDate = Date.today
    result = RuleNew.compute_feature([displayDate.to_s, nil], pid = 999)
    result.save unless result.nil?
    saved_spec = BinSpec.find_by_product_id_and_name(999, RuleNew.feature_name)
    assert_not_nil saved_spec, 'BinSpec should be saved for product that is new'
    assert saved_spec.value, 'BinSpec value for new product should be true'
    
    # preorderDate = today
    preorderDate = Date.today
    result = RuleNew.compute_feature([nil, preorderDate.to_s], pid = 999)
    result.save unless result.nil?
    saved_spec = BinSpec.find_by_product_id_and_name(999, RuleNew.feature_name)
    assert_not_nil saved_spec, 'BinSpec should be saved for product that is new'
    assert saved_spec.value, 'BinSpec value for new product should be true'
    
    # preorderDate > now, no displayDate
    preorderDate = Date.today + 1
    result = RuleNew.compute_feature([nil, preorderDate.to_s], pid = 999)
    result.save unless result.nil?
    saved_spec = BinSpec.find_by_product_id_and_name(999, RuleNew.feature_name)
    assert_nil saved_spec, 'BinSpec for new should not be present for product that is not new'
    
    # displayDate > today (?), preorderDate > today
    displayDate = Date.today + 1
    preorderDate = Date.today + 20
    result = RuleNew.compute_feature([nil, preorderDate.to_s], pid = 999)
    result.save unless result.nil?
    saved_spec = BinSpec.find_by_product_id_and_name(999, RuleNew.feature_name)
    assert_nil saved_spec, 'BinSpec for new should not be present for product that is not new'
  end
  
  # test "calculating factors" do
  # product1 = create(:product)
  # product2 = create(:product)
  # retrieved_product = Product.cached(product1.id)
  # retrieved_all_products = Product.manycached([product1.id, product2.id])
  # 
  # assert_equal product1, retrieved_product, "retrieved product not the same as original"
  # assert_not_nil retrieved_all_products.index(product1), "could not find project in cache"
  # assert_not_nil retrieved_all_products.index(product2), "could not find project in cache"
  #   CategoricalFacetValue.create(:id => 2, :facet_id => 6, :name => "Canon", :value => 1)
  #       
  #   Product.calculate_factors
  #   
  #   pid = products(:oneproduct).id
  #   
  #   # check that factors were computed for the product for the 
  #   saleprice_spec = ContSpec.find_by_product_id_and_name(pid, 'saleprice_factor')
  #   
  #   # check that that the specs and utility values are not nil for that product
  #   assert_not_nil saleprice_spec
  #   assert_in_delta rating_spec.value, 0.0, 0.000001
  #   assert_equal 0, Product.calculateFactor_rating(rating1)
  #   rating2 = 4.0                                          
  #   assert_equal 1, Product.calculateFactor_rating(rating2)
  #   rating3 = 5.0                                          
  #   assert_equal 1, Product.calculateFactor_rating(rating3)
  # end 
  # 
  # test "Product and Spec import from BBY API" do
  #   sr = create(:scraping_rule, local_featurename: "longDescription", remote_featurename: "longDescription", rule_type: "Text")
  #   Product.feed_update
  #   # 20 created(Current BB page size), and 1 in the fixtures
  #   assert_equal 21, Product.count, "There should be 20 products created in the database"
  #   assert_equal true, Product.all.inject(true){|res,el|res && (el.instock || /^B/ =~ el.sku)}, "All products should be instock (unless they're bundles)"
  #   assert !Product.all[1].text_specs.empty?, "New products should have one texttspec"
  # end
  # 
  # test "Product and Spec import for bundles from BBY API" do
  #   sr = create(:scraping_rule, local_featurename: "price", remote_featurename: "regularPrice", rule_type: "Continuous")
  #   Product.feed_update
  #   # 20 created(Current BB page size), and 1 in the fixtures
  #   assert_equal 21, Product.count, "There should be 20 products created in the database"
  #   assert_equal true, Product.all.inject(true){|res,el|res && el.instock}, "All products should be instock"
  #   assert !Product.all[1].cont_specs.empty?, "New products should have one texttspec"
  #   assert_equal ["price"]*20, Product.all[1..-1].map{|p|p.cont_specs.first.try(:name)}, "Test that the price is available"
  #   assert_match /\d+(\.\d+)?/, Product.first.cont_specs.first.try(:value).to_s, "Prices are actually recorded correctly"
  # end
  # 
  # test "Get Rules" do
  #   sr = create(:scraping_rule, local_featurename: "longDescription", remote_featurename: "longDescription")
  #   myrules = ScrapingRule.get_rules([],false)
  #   assert_equal sr, myrules.first[:rule], "Get Rules should return the singular rules in this case"
  # end
end
