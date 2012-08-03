require 'test_helper'

class CustomizationTest < ActiveSupport::TestCase
  
  setup do
    create(:product_category, product_type: 'FDepartments', l_id: 1, r_id: 4310)
    create(:product_category, product_type: 'F1127', l_id: 830, r_id: 839)
    
    # FIXME: following are now required because error thrown if no sr found for any of the custom rules 
    create(:scraping_rule, local_featurename: "saleEndDate", rule_type: 'Categorical', product_type: 'F1127')
    create(:scraping_rule, local_featurename: "displayDate", rule_type: 'Categorical', product_type: 'F1127')
    create(:scraping_rule, local_featurename: "preorderReleaseDate", rule_type: 'Categorical', product_type: 'F1127')
    Session.new('F1127')
  end
  
  test "compute specs" do
    p1 = create(:product, sku: 901)
    p2 = create(:product, sku: 903)
    # onsale
    CatSpec.create(:product_id => p1.id, :name => 'saleEndDate', :value => Date.today.to_s)
    ContSpec.create(:product_id => p1.id, :name => 'price', :value => 100)
    ContSpec.create(:product_id => p1.id, :name => 'saleprice', :value => 99.95)
    CatSpec.create(:product_id => p2.id, :name => 'saleEndDate', :value => (Date.today-10).to_s)
    results = Customization.run([p1.id, p2.id])[BinSpec]
    assert_not_empty results.select{|spec| spec.name == "onsale" && spec.product_id = p1.id && spec.value == true}
    assert_empty results.select{|spec| spec.name == "onsale" && spec.product_id == p2.id}
  end
  
  test "Usage Type Rule" do
    # for an sku that's in category x, run the rule computation, check that there's a spec created for that category and that product
    # 10206581 is in everyday but no other category
    p1 = create(:product, sku: '10208202')
    #CatSpec.create(:product_id => p1.id, :name => 'product_type', :value => 'F28357')
    result = RuleUsageType.group_computation([p1.id])
    assert_equal 1, result.length, 'Only one usage type should be present for this sku'
    result.map(&:save) unless result.nil?
    
    saved_spec = BinSpec.find_by_product_id_and_name(p1.id, "usageType_Everyday")
    assert_not_nil saved_spec, 'BinSpec should be present'
    
    # for sku 10195304 that is in 2 categories (Microsoft Premium Collection PC and Ultrabook)
    p2 = create(:product, sku: '10208037')
    result = RuleUsageType.group_computation([p2.id])
    assert_equal 2, result.length, 'Two usage types should be present for this sku'
    result.map(&:save) unless result.nil?
    first_saved_spec = BinSpec.find_by_product_id_and_name(p2.id, RuleUsageType.feature_name + '_' + "MicrosoftPremiumCollectionPC")
    second_saved_spec = BinSpec.find_by_product_id_and_name(p2.id, RuleUsageType.feature_name + '_' + "Ultrabook")
    assert_not_nil first_saved_spec, "Usage type should be saved as expected"
    assert_not_nil second_saved_spec, "Usage type should be saved as expected"
    
    p3 = create(:product, sku: '10208920')
    BinSpec.create(:product_id => p3.id, :name => 'usageType_OntheGo', :value => true)
    result = RuleUsageType.group_computation([p1.id, p2.id, p3.id])
    result.map(&:save) unless result.nil?
    saved_spec = BinSpec.find_by_product_id_and_name(p3.id, 'usageType_OntheGo')
    assert_nil saved_spec, "Usage type no longer in the feed should not be present for this product"
  end
  
  test "Rule Price Plus EHF" do
    # test a product with nil EHF but a saleprice value
    result = RulePriceplusehf.compute([15.00, nil], pid = 999)
    result.save unless result.nil?
    saved_spec = ContSpec.find_by_product_id_and_name(999, RulePriceplusehf.feature_name)
    assert_not_nil saved_spec, 'Spec should have been computed for nil EHF'
    assert_in_delta 15.0, saved_spec.value, 0.001, "derived value should be computed accurately"
    
    # test a product with zero EHF
    result = RulePriceplusehf.compute([15.00, 0], pid = 999)
    result.save unless result.nil?
    saved_spec = ContSpec.find_by_product_id_and_name(999, RulePriceplusehf.feature_name)
    assert_not_nil saved_spec, 'Spec should have been computed for 0 EHF'
    assert_in_delta 15.0, saved_spec.value, 0.001, "derived value should be computed accurately"
    
    # test a product with a negative EHF
    result = RulePriceplusehf.compute([15.00, -3.1], pid = 901)
    result.save unless result.nil?
    saved_spec = ContSpec.find_by_product_id_and_name(901, RulePriceplusehf.feature_name)
    assert_nil saved_spec, 'Spec should not have been computed for -ve EHF'
    
    # test a product with a positive EHF
    result = RulePriceplusehf.compute([15.00, 3.10], pid = 999)
    result.save unless result.nil?
    saved_spec = ContSpec.find_by_product_id_and_name(999, RulePriceplusehf.feature_name)
    assert_not_nil saved_spec, 'Spec should have been computed'
    assert_in_delta 18.10, saved_spec.value, 0.001, "derived value should be computed accurately"
  end
  
  test "Coming Soon Rule" do
    # preorder date < today : false
    preorderDate = Date.today - 1
    result = RuleComingSoon.compute([preorderDate.to_s], pid = 999)
    result.save unless result.nil?
    saved_spec = BinSpec.find_by_product_id_and_name(999, RuleComingSoon.feature_name)
    assert_nil saved_spec, 'BinSpec should not be present for false rule value'
    
    # preorder date = today : false
    preorderDate = Date.today
    result = RuleComingSoon.compute([preorderDate.to_s], pid = 999)
    result.save unless result.nil?
    saved_spec = BinSpec.find_by_product_id_and_name(999, RuleComingSoon.feature_name)
    assert_nil saved_spec, 'BinSpec should not be present for false rule value'
    
    # preorder date > today : true
    preorderDate = Date.today + 1
    result = RuleComingSoon.compute([preorderDate.to_s], pid = 999)
    result.save unless result.nil?
    saved_spec = BinSpec.find_by_product_id_and_name(999, RuleComingSoon.feature_name)
    assert_not_nil saved_spec, 'BinSpec should be saved for product that is new'
    assert saved_spec.value, 'BinSpec value should be true'
    
    # test invalid preorder date : catch exception thrown
    preorderDate = "2010-10-00"
    assert_raise(ArgumentError) { RuleComingSoon.compute([preorderDate.to_s], pid = 999) }
  end
  
  test "Rule On Sale" do
    # saleEndDate was not present or past (i.e. product didn't have an onsale spec),
    # is now has saleEndDate set to future date -> onSale
    #flunk('this test throws an error for rule_on_sale line 14 NoMethodError: undefined method > for nil:NilClass')
    
    assert_nil BinSpec.find_by_product_id_and_name(911, RuleOnSale.feature_name)
    saleEndDate = Date.today + 1
    result = RuleOnSale.compute([saleEndDate.to_s, 2, 1], pid = 911)
    result.save unless result.nil?
    saved_spec = BinSpec.find_by_product_id_and_name(911, RuleOnSale.feature_name)
    assert_not_nil saved_spec, 'BinSpec should be saved for true condition'
    assert saved_spec.value, 'BinSpec value should be true'
    
    # saleEndDate was present / future and is now set to today -> onSale
    old_spec = BinSpec.find_by_product_id_and_name(911, RuleOnSale.feature_name)
    assert_not_nil old_spec, 'prerequisite for test'
    saleEndDate = Date.today
    result = RuleOnSale.compute([saleEndDate.to_s, 2, 1], pid = 911)
    result.save unless result.nil?
    saved_spec = BinSpec.find_by_product_id_and_name(911, RuleOnSale.feature_name)
    assert_not_nil saved_spec, 'BinSpec should be saved for true condition'
    assert saved_spec.value, 'BinSpec value should be true'
    
    # onsale was true, now sale end date in the past -> not on sale
    old_spec = BinSpec.find_by_product_id_and_name(911, RuleOnSale.feature_name)
    assert_not_nil old_spec, 'prerequisite for test'
    saleEndDate = Date.today - 1
    result = RuleOnSale.compute([saleEndDate.to_s, 2, 2], pid = 911)
    result.save unless result.nil?
    saved_spec = BinSpec.find_by_product_id_and_name(911, RuleOnSale.feature_name)
    assert_nil saved_spec, 'BinSpec should not be present for false rule value'
    
    # no saleEndDate -> not on sale
    result = RuleOnSale.compute([nil, 2, 2], pid = 911)
    result.save unless result.nil?
    saved_spec = BinSpec.find_by_product_id_and_name(911, RuleOnSale.feature_name)
    assert_nil saved_spec, 'BinSpec should not be present for false rule value'
    
    saleEndDate = "2010-10-00"
    assert_raise(ArgumentError) { RuleOnSale.compute([saleEndDate.to_s], pid = 911) }
  end
  
  test "Rule New" do
    # inputs:
    # displayDate > 30days ago, < today AND preorderDate = 30 days ago
    displayDate = Date.today - 29
    preorderDate = Date.today - 30
    result = RuleNew.compute([displayDate.to_s, preorderDate.to_s], pid = 999)
    result.save unless result.nil?
    
    saved_spec = BinSpec.find_by_product_id_and_name(999, RuleNew.feature_name)
    assert_not_nil saved_spec, 'BinSpec should be saved for product that is new'
    assert saved_spec.value, 'BinSpec value for new product should be 1'
    
    # displayDate < 30days ago, no preorderDate
    displayDate = Date.today - 31
    result = RuleNew.compute([displayDate.to_s, nil], pid = 999)
    result.save unless result.nil?
    # check that there was a binspec saved
    saved_spec = BinSpec.find_by_product_id_and_name(999, RuleNew.feature_name)
    assert_nil saved_spec, 'BinSpec for new should not be present for product that is not new'
    
    # preorderDate = 31 days ago, no displayDate
    preorderDate = Date.today - 31
    result = RuleNew.compute([nil, preorderDate.to_s], pid = 999)
    result.save unless result.nil?
    saved_spec = BinSpec.find_by_product_id_and_name(999, RuleNew.feature_name)
    assert_nil saved_spec, 'BinSpec for new should not be present for product that is not new'
    
    # displayDate = today
    displayDate = Date.today
    result = RuleNew.compute([displayDate.to_s, nil], pid = 999)
    result.save unless result.nil?
    saved_spec = BinSpec.find_by_product_id_and_name(999, RuleNew.feature_name)
    assert_not_nil saved_spec, 'BinSpec should be saved for product that is new'
    assert saved_spec.value, 'BinSpec value for new product should be true'
    
    # preorderDate = today
    preorderDate = Date.today
    result = RuleNew.compute([nil, preorderDate.to_s], pid = 999)
    result.save unless result.nil?
    saved_spec = BinSpec.find_by_product_id_and_name(999, RuleNew.feature_name)
    assert_not_nil saved_spec, 'BinSpec should be saved for product that is new'
    assert saved_spec.value, 'BinSpec value for new product should be true'
    
    # preorderDate > now, no displayDate
    preorderDate = Date.today + 1
    result = RuleNew.compute([nil, preorderDate.to_s], pid = 999)
    result.save unless result.nil?
    saved_spec = BinSpec.find_by_product_id_and_name(999, RuleNew.feature_name)
    assert_nil saved_spec, 'BinSpec for new should not be present for product that is not new'
    
    # displayDate > today (?), preorderDate > today
    displayDate = Date.today + 1
    preorderDate = Date.today + 20
    result = RuleNew.compute([nil, preorderDate.to_s], pid = 999)
    result.save unless result.nil?
    saved_spec = BinSpec.find_by_product_id_and_name(999, RuleNew.feature_name)
    assert_nil saved_spec, 'BinSpec for new should not be present for product that is not new'
  end
  
  test "Rule Average Sales" do
    p1 = create(:product, sku: 901)
    p2 = create(:product, sku: 902)
    
    # test when no daily specs
    result = RuleAverageSales.group_computation([p1.id,p2.id])
    assert_empty result, 'no average sales'
    
    # test only one product
    DailySpec.create(:sku => p1.sku, :name => 'online_orders', :date => (Date.today-5).to_s, :value_flt => 4)
    DailySpec.create(:sku => p1.sku, :name => 'online_orders', :date => (Date.today-1).to_s, :value_flt => 2)
    result = RuleAverageSales.group_computation([p1.id])
    assert_not_empty result, "computation should return a list of results"
    result.each {|r| r.save}
    saved_spec = ContSpec.find_by_product_id_and_name(p1.id, RuleAverageSales.feature_name)
    assert_not_nil saved_spec, "spec should be created"
    assert_equal 3, saved_spec.value, "derived value should be computed properly"
    
    # test two products, one with 0 orders
    DailySpec.create(:sku => p2.sku, :name => 'online_orders', :date => (Date.today-5).to_s, :value_flt => 10)
    DailySpec.create(:sku => p2.sku, :name => 'online_orders', :date => (Date.today-1).to_s, :value_flt => 0)
    DailySpec.create(:sku => p2.sku, :name => 'online_orders', :date => (Date.today-3).to_s, :value_flt => 0)
    DailySpec.create(:sku => p2.sku, :name => 'online_orders', :date => (Date.today-2).to_s, :value_flt => 0)
    result = RuleAverageSales.group_computation([p1.id,p2.id])
    assert_equal 2, result.length
    result.each {|r| r.save}
    spec1 = ContSpec.find_by_product_id_and_name(p1.id, RuleAverageSales.feature_name)
    spec2 = ContSpec.find_by_product_id_and_name(p2.id, RuleAverageSales.feature_name)
    assert_not_nil spec1, "spec should be created"
    assert_not_nil spec2, "spec should be created"
    assert_equal 3, spec1.value, "derived value should be computed properly"
    assert_in_delta 2.5, spec2.value, 0.00001, "derived value should be computed properly"
    
    # boundary test: 30 days back, 31 days back
    DailySpec.create(:sku => p1.sku, :name => 'online_orders', :date => (Date.today-30).to_s, :value_flt => 3)
    DailySpec.create(:sku => p1.sku, :name => 'online_orders', :date => (Date.today-31).to_s, :value_flt => 10)
    result = RuleAverageSales.group_computation([p1.id])
    assert_not_empty result, "computation should return a list of results"
    result.each {|r| r.save}
    saved_spec = ContSpec.find_by_product_id_and_name(p1.id, RuleAverageSales.feature_name)
    assert_not_nil saved_spec, "spec should be created"
    assert_equal 3, saved_spec.value, "derived value should be computed properly"
  end
  
  def top_20_rule_tests(input_spec_name, rule_name)
    p1 = create(:product, sku: 901)
    p2 = create(:product, sku: 902)
    p3 = create(:product, sku: 903)
    p4 = create(:product, sku: 904)
    p5 = create(:product, sku: 905)
    p6 = create(:product, sku: 906)
    
    DailySpec.create(:sku => p1.sku, :name => input_spec_name, :date => Date.today.to_s, :value_flt => 4)
    DailySpec.create(:sku => p1.sku, :name => input_spec_name, :date => (Date.today-1).to_s, :value_flt => 3)
    DailySpec.create(:sku => p2.sku, :name => input_spec_name, :date => Date.today.to_s, :value_flt => 3)
    DailySpec.create(:sku => p3.sku, :name => input_spec_name, :date => Date.today.to_s, :value_flt => 0)
    DailySpec.create(:sku => p4.sku, :name => input_spec_name, :date => Date.today.to_s, :value_flt => 0)
    DailySpec.create(:sku => p5.sku, :name => input_spec_name, :date => Date.today.to_s, :value_flt => 3)
    
    result = rule_name.group_computation([p6.id])
    assert_empty result, "product with no input values in DailySpecs should not be a bestseller"
    
    result = rule_name.group_computation([p3.id, p4.id])
    assert_empty result, "no spec created for a set with all 0 "
    result = rule_name.group_computation([p2.id])
    result.each {|r| r.save}
    assert_not_empty result, "spec created for a single product with non-0 input specs"
    saved_spec = BinSpec.find_by_product_id_and_name(p2.id, rule_name.feature_name)
    assert_not_nil saved_spec, "spec created for a single product with non-0 input specs"
    assert saved_spec.value, "spec true created for a single product with non-0 input specs"
    
    # different order numbers
    oldspec = BinSpec.find_by_product_id_and_name(p1.id, rule_name.feature_name)
    oldspec.destroy unless oldspec.nil?
    oldspec = BinSpec.find_by_product_id_and_name(p2.id, rule_name.feature_name)
    oldspec.destroy unless oldspec.nil?
    results = rule_name.group_computation([p1.id, p2.id, p3.id, p6.id])
    results.each {|r| r.save}
    assert_not_empty results, "spec created for some product with non-0 input specs"
    assert_not_empty results.select{|spec| spec.name == rule_name.feature_name && spec.product_id == p1.id && spec.value == true}
    assert_empty results.select{|spec| spec.name == rule_name.feature_name && spec.product_id == p2.id}
    assert_empty results.select{|spec| spec.name == rule_name.feature_name && spec.product_id == p3.id}
    assert_empty results.select{|spec| spec.name == rule_name.feature_name && spec.product_id == p4.id}
    assert_empty results.select{|spec| spec.name == rule_name.feature_name && spec.product_id == p6.id}
    assert_not_nil BinSpec.find_by_product_id_and_name(p1.id, rule_name.feature_name)
    assert_nil BinSpec.find_by_product_id_and_name(p2.id, rule_name.feature_name)
    
    # all equal number of input specs
    results = rule_name.group_computation([p2.id, p5.id])
    results.each {|r| r.save}
    assert_not_empty results, 'all products with max non-0 number of input specs should be top viewed'
    assert_not_empty results.select{|spec| spec.name == rule_name.feature_name && spec.product_id == p2.id && spec.value == true}
    assert_not_empty results.select{|spec| spec.name == rule_name.feature_name && spec.product_id == p5.id && spec.value == true}
    
    # make sure non-promo week input specs are excluded
    DailySpec.create(:sku => p6.id, :name => input_spec_name, :date => (Date.today-10).to_s, :value_flt => 3)
    result = rule_name.group_computation([p6.id])
    results.each {|r| r.save}
    assert_empty result, "input values not in the promo week are not considered"
    assert_nil BinSpec.find_by_product_id_and_name(p6.id, rule_name.feature_name)
    
    # last friday should be included in promo week
    lastFriday = Date.today - (Date.today.wday - 5) % 7
    DailySpec.create(:sku => p6.sku, :name => input_spec_name, :date => lastFriday.to_s, :value_flt => 3)
    result = rule_name.group_computation([p6.id])
    result.each {|r| r.save}
    assert_not_empty result, "last friday should be included in promo week"
    assert_not_empty result.select{|spec| spec.name == rule_name.feature_name && spec.product_id == p6.id && spec.value == true}
    
    # computing rule should fail on invalid pid
    inexistant_pid = p6.id*100+1
    assert_raise(ActiveRecord::RecordNotFound) { rule_name.group_computation([inexistant_pid])}
  end
  
  test "Rule TopViewed" do
    top_20_rule_tests('pageviews', RuleTopViewed)
  end
  
  test "Rule BestSeller" do
    top_20_rule_tests('online_orders', RuleBestSeller)
  end
  
  test "Rule Utility" do
    # Tests must cover all 6 types, plus their internal sorting:
    # From the documentation:
    # "Featured products shall be displayed until
    # => all spots are filled based on the following rules in this order:
    # =>  Advertised SKUs, Advertised SKUs without savings,
    # =>  Unadvertised SKUs with savings, Best sellers,
    # =>  Most popular based on page views/PDP visits and prices high to low
    #
    # Advertised SKUs shall be sorted by largest savings claim % off
    # Advertised SKUs without savings shall be sorted by newest display date
    # Unadvertised SKUs with savings shall be sorted by largest savings claims % off"

    # Therefore 9 products should be tested
    # => 2 Advertised SKUs
    # => 2 Advertised SKUs without savings
    # => 2 Unadvertised SKUs with savings
    # => 1 Best seller with high page views
    # => 1 Best Seller with lower page views
    # => 1 Out of stock to ensure it doesn't get computed
    
    create(:product_category, product_type: 'BDepartments', l_id: 1, r_id: 5000, retailer: 'B')
    create(:product_category, product_type: 'B20270', l_id: 400, r_id: 1800)
    create(:product_category, product_type: 'B20218', l_id: 600, r_id: 1200)
    create(:product_category, product_type: 'B20282', l_id: 650, r_id: 710)
    create(:product_category, product_type: 'B20232', l_id: 700, r_id: 701)

    Session.new('B20232')

    adv1 = create(:product, sku: 900, retailer: 'B')
    adv2 = create(:product, sku: 901, retailer: 'B')
    adv_no_save1 = create(:product, sku: 902, retailer: 'B')
    adv_no_save2 = create(:product, sku: 903, retailer: 'B')
    unadv1 = create(:product, sku: 904, retailer: 'B')
    unadv2 = create(:product, sku: 905, retailer: 'B')
    best1 = create(:product, sku: 906, retailer: 'B')
    best2 = create(:product, sku: 907, retailer: 'B')
    out_of_stock = create(:product, sku: 908, instock: 0, retailer: 'B')

    # Advertised SKU, highest savings
    create(:cat_spec, product_id: adv1.id, name: "brand", value: "LIQUID IMAGE")
    create(:bin_spec, product_id: adv1.id, name: "hdmi", value: 1)
    create(:cont_spec, product_id: adv1.id, name: "customerRating", value: 4)
    create(:cont_spec, product_id: adv1.id, name: "price", value: 99.99)
    create(:cont_spec, product_id: adv1.id, name: "saleprice", value: 49.99)
    create(:cat_spec, product_id: adv1.id, name: "displayDate", value: "2011-05-12")
    create(:cat_spec, product_id: adv1.id, name: "saleEndDate", value: "2012-05-20")
    create(:bin_spec, product_id: adv1.id, name: "isAdvertised", value: 1)

    # Advertised SKU, lower savings
    create(:cat_spec, product_id: adv2.id, name: "brand", value: "CANON")
    create(:bin_spec, product_id: adv2.id, name: "hdmi", value: 1)
    create(:cont_spec, product_id: adv2.id, name: "customerRating", value: 4)
    create(:cont_spec, product_id: adv2.id, name: "price", value: 99.99)
    create(:cont_spec, product_id: adv2.id, name: "saleprice", value: 69.99)
    create(:cat_spec, product_id: adv2.id, name: "displayDate", value: "2011-05-12")
    create(:cat_spec, product_id: adv2.id, name: "saleEndDate", value: "2012-05-20")
    create(:bin_spec, product_id: adv2.id, name: "isAdvertised", value: 1)

    # Advertised SKU, no savings, newest display date
    create(:cat_spec, product_id: adv_no_save1.id, name: "brand", value: "AGPHA")
    create(:cat_spec, product_id: adv_no_save1.id, name: "color", value: "RED")
    create(:bin_spec, product_id: adv_no_save1.id, name: "frontlcd", value: 1)
    create(:cont_spec, product_id: adv_no_save1.id, name: "customerRating", value: 2)
    create(:cont_spec, product_id: adv_no_save1.id, name: "price", value: 400.99)
    create(:cont_spec, product_id: adv_no_save1.id, name: "saleprice", value: 400.99)
    create(:cat_spec, product_id: adv_no_save1.id, name: "displayDate", value: "2011-11-12")
    create(:bin_spec, product_id: adv_no_save1.id, name: "isAdvertised", value: 1)

    # Advertised SKU, no savings, older display date
    create(:cat_spec, product_id: adv_no_save2.id, name: "brand", value: "AGPHA")
    create(:cat_spec, product_id: adv_no_save2.id, name: "color", value: "RED")
    create(:bin_spec, product_id: adv_no_save2.id, name: "frontlcd", value: 1)
    create(:cont_spec, product_id: adv_no_save2.id, name: "customerRating", value: 2)
    create(:cont_spec, product_id: adv_no_save2.id, name: "price", value: 400.99)
    create(:cont_spec, product_id: adv_no_save2.id, name: "saleprice", value: 400.99)
    create(:cat_spec, product_id: adv_no_save2.id, name: "displayDate", value: "2011-09-12")
    create(:bin_spec, product_id: adv_no_save2.id, name: "isAdvertised", value: 1)

    # Unadvertised SKU, highest savings
    create(:cat_spec, product_id: unadv1.id, name: "brand", value: "LIQUID IMAGE")
    create(:bin_spec, product_id: unadv1.id, name: "hdmi", value: 1)
    create(:cont_spec, product_id: unadv1.id, name: "customerRating", value: 4)
    create(:cont_spec, product_id: unadv1.id, name: "price", value: 99.99)
    create(:cont_spec, product_id: unadv1.id, name: "saleprice", value: 49.99)
    create(:cat_spec, product_id: unadv1.id, name: "displayDate", value: "2011-05-12")
    create(:cat_spec, product_id: unadv1.id, name: "saleEndDate", value: "2012-05-20")

    # Unadvertised SKU, lower savings
    create(:cat_spec, product_id: unadv2.id, name: "brand", value: "CANON")
    create(:bin_spec, product_id: unadv2.id, name: "hdmi", value: 1)
    create(:cont_spec, product_id: unadv2.id, name: "customerRating", value: 4)
    create(:cont_spec, product_id: unadv2.id, name: "price", value: 299.99)
    create(:cont_spec, product_id: unadv2.id, name: "saleprice", value: 269.99)
    create(:cat_spec, product_id: unadv2.id, name: "displayDate", value: "2011-05-12")
    create(:cat_spec, product_id: unadv2.id, name: "saleEndDate", value: "2012-05-20")

    # Best seller, high page views
    create(:cont_spec, product_id: best1.id, name: "price", value: 229.99)
    create(:cont_spec, product_id: best1.id, name: "saleprice", value: 229.99)
    create(:cat_spec, product_id: best1.id, name: "displayDate", value: "2011-11-20")
    create(:cont_spec, product_id: best1.id, name: "averageSales", value: 7.4)
    create(:cont_spec, product_id: best1.id, name: "averagePageviews", value: 12)

    # Best seller, lower page views
    create(:cont_spec, product_id: best2.id, name: "price", value: 199.99)
    create(:cont_spec, product_id: best2.id, name: "saleprice", value: 199.99)
    create(:cat_spec, product_id: best2.id, name: "displayDate", value: "2011-11-20")
    create(:cont_spec, product_id: best2.id, name: "averageSales", value: 6)
    create(:cont_spec, product_id: best2.id, name: "averagePageviews", value: 8)

    # Out of stock
    create(:cont_spec, product_id: out_of_stock.id, name: "price", value: 300.99)
    create(:cont_spec, product_id: out_of_stock, name: "saleprice", value: 280.99)
    create(:cat_spec, product_id: out_of_stock.id, name: "saleEndDate", value: "2012-03-20")

    create(:facet, name: "hdmi", feature_type: "Binary", used_for: "utility", value: -0.06, product_type: "B20218")
    create(:facet, name: "frontlcd", feature_type: "Binary", used_for: "utility", value: 0.4, product_type: "B20218")
    
    result = RuleUtility.group_computation( [ adv1.id, adv2.id, adv_no_save1.id, adv_no_save2.id, unadv1.id, unadv2.id, best1.id, best2.id ] )
    
    # Test for successful computation
    assert_not_nil result.select{|spec| spec.name == "utility" && spec.product_id == adv1.id}.map(&:value)
    assert_not_nil result.select{|spec| spec.name == "utility" && spec.product_id == adv2.id}.map(&:value)
    assert_not_nil result.select{|spec| spec.name == "utility" && spec.product_id == adv_no_save1.id}.map(&:value)
    assert_not_nil result.select{|spec| spec.name == "utility" && spec.product_id == adv_no_save2.id}.map(&:value)
    assert_not_nil result.select{|spec| spec.name == "utility" && spec.product_id == unadv1.id}.map(&:value)
    assert_not_nil result.select{|spec| spec.name == "utility" && spec.product_id == unadv2.id}.map(&:value)
    assert_not_nil result.select{|spec| spec.name == "utility" && spec.product_id == best1.id}.map(&:value)
    assert_not_nil result.select{|spec| spec.name == "utility" && spec.product_id == best2.id}.map(&:value)


    # Test for order
    # adv1 should be befor adv2
    assert_operator result.select{|spec| spec.name == "utility" && spec.product_id == adv1.id}.map(&:value)[0], :>=, result.select{|spec| spec.name == "utility" && spec.product_id == adv2.id}.map(&:value)[0]

    # adv2 should be before adv_no_sales1
    assert_operator result.select{|spec| spec.name == "utility" && spec.product_id == adv2.id}.map(&:value)[0], :>=, result.select{|spec| spec.name == "utility" && spec.product_id == adv_no_save1.id}.map(&:value)[0]

    # adv_no_sales1 should be before adv_no_sales2
    assert_operator result.select{|spec| spec.name == "utility" && spec.product_id == adv_no_save1.id}.map(&:value)[0], :>=, result.select{|spec| spec.name == "utility" && spec.product_id == adv_no_save2.id}.map(&:value)[0]

    # adv_no_sales2 should be before unadv1
    assert_operator result.select{|spec| spec.name == "utility" && spec.product_id == adv_no_save2.id}.map(&:value)[0], :>=, result.select{|spec| spec.name == "utility" && spec.product_id == unadv1.id}.map(&:value)[0]

    # unadv1 should be before unadv2
    assert_operator result.select{|spec| spec.name == "utility" && spec.product_id == unadv1.id}.map(&:value)[0], :>=, result.select{|spec| spec.name == "utility" && spec.product_id == unadv2.id}.map(&:value)[0]

    # unadv2 should be before best1
    assert_operator result.select{|spec| spec.name == "utility" && spec.product_id == unadv2.id}.map(&:value)[0], :>=, result.select{|spec| spec.name == "utility" && spec.product_id == best1.id}.map(&:value)[0]

    # best1 should be before best 2
    assert_operator result.select{|spec| spec.name == "utility" && spec.product_id == best1.id}.map(&:value)[0], :>=, result.select{|spec| spec.name == "utility" && spec.product_id == best2.id}.map(&:value)[0]


    # Test that out-of-stock products do not get computed
    assert_empty result.select{|spec| spec.name = "utility" && spec.product_id == out_of_stock.id}
  end
end
