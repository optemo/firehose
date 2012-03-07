require 'test_helper'

class CustomizationTest < ActiveSupport::TestCase
  
  setup do
    create(:product_category, product_type: 'F1127')
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
    CatSpec.create(:product_id => p2.id, :name => 'saleEndDate', :value => (Date.today-10).to_s)
    results = Customization.compute_specs([p1.sku, p2.sku])[BinSpec]
    assert_not_empty results.select{|spec| spec.name == "onsale" && spec.product_id = p1.id && spec.value == true}
    assert_empty results.select{|spec| spec.name == "onsale" && spec.product_id == p2.id}
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
  
  test "Rule Bestseller" do
    flunk
  end
end
