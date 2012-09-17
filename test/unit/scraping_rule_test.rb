require 'test_helper'

class ScrapingRuleTest < ActiveSupport::TestCase
  test "Get Rules" do
    Session.new "B20218"
    sr = create(:scraping_rule, local_featurename: "longDescription", remote_featurename: "longDescription")
    myrules = ScrapingRule.get_rules([],false)
    assert_equal sr, myrules.first[:rule], "Get Rules should return the singular rules in this case"
  end
  
  test "validations" do
    sr1 = build(:scraping_rule, :local_featurename => nil)
    assert !sr1.save, "must have local_featurename"
    sr1 = build(:scraping_rule, :remote_featurename => nil)
    assert !sr1.save, "must have remote_featurename"
    sr1 = build(:scraping_rule, :regex => nil)
    assert !sr1.save, "must have regex"
    sr1 = build(:scraping_rule, :product_type => nil)
    assert !sr1.save, "must have product_type"
    sr1 = build(:scraping_rule, :product_type => nil)
    assert !sr1.save, "must have product_type"
    sr1 = build(:scraping_rule, :rule_type => nil)
    assert !sr1.save, "must have rule_type"
    sr1 = build(:scraping_rule, :rule_type => 'Binary', :bilingual => true)
    assert !sr1.save, "Bilingual can only be true for Categorical rules"
    sr1 = build(:scraping_rule, :local_featurename => "Name.withperiod")
    assert !sr1.save, "local_featurename with punctuation not allowed"
    sr1 = build(:scraping_rule, :local_featurename => "Name with spaces")
    assert !sr1.save, "local_featurename with spaces not allowed"
  end
  
  test "scraping" do
    Session.new("B20218")
    # Make Rules (these are applied according to when they were defined -> first one will give first candidate)
    create :scraping_rule, local_featurename: 'regular', remote_featurename: 'specs.Physical Features.Colour', rule_type: 'Categorical', regex: 'Black|Blue|Brown', bilingual: false
    create :scraping_rule, local_featurename: 'consecutive_fr_trans', remote_featurename: 'specs.Physical Features.Colour', rule_type: 'Categorical', regex: 'Pink/Rose^^Black/Noir^^Bla/Noi', bilingual: false
    create :scraping_rule, local_featurename: 'consecutive_order', remote_featurename: 'specs.Physical Features.Colour', rule_type: 'Categorical', regex: 'Pink/Rose^^Bla/Noi^^Black/Noir', bilingual: false
    
    create :scraping_rule, local_featurename: 'bi_regular', remote_featurename: 'specs.Physical Features.Colour', rule_type: 'Categorical', regex: 'Black|Blue|Brown', bilingual: true
    create :scraping_rule, local_featurename: 'bi_consecutive_fr_trans', remote_featurename: 'specs.Physical Features.Colour', rule_type: 'Categorical', regex: 'Pink/Rose^^Black/Noir^^Bla/Noi', bilingual: true
    create :scraping_rule, local_featurename: 'bi_consecutive_order', remote_featurename: 'specs.Physical Features.Colour', rule_type: 'Categorical', regex: 'Pink/Rose^^Bla/Noi^^Black/Noir', bilingual: true
    
    # Stub the product_search API call to return stored data.
    BestBuyApi.stubs(:product_search).with{|id| id == "100000"}.returns(JSON.parse($bb_api_response["100000"]))
    BestBuyApi.stubs(:product_search).with{|id| id == "100001"}.returns(JSON.parse($bb_api_response["100001"]))
 
    # Call scraping on products
    number1 = ScrapingRule.scrape((BBproduct.new id: "100000", category: "B20218"),false,[],false)
    candidates1 = number1[:candidates] # Colour: Black
    translations1 = number1[:translations] # Colour: Black
    number2 = ScrapingRule.scrape((BBproduct.new id: "100001", category: "B20218"),false,[],false)
    candidates2 = number2[:candidates] # Colour: Silver
    translations2 = number2[:translations] # Colour: Silver
    
    # Check candidates
      # regular regex
      assert_equal "black", candidates1[0].parsed, "Data should have matched"
      assert_equal nil, candidates2[0].parsed,  "Data should not have matched"
      
      # consecutive_fr_trans regex
      assert_equal "noir", candidates1[1].parsed, "Data should have matched"
      assert_equal nil, candidates2[1].parsed,  "Data should not have matched"
        
      # consecutive_order
      assert_equal "noi", candidates1[2].parsed, "Should have returned the first match"
      assert_equal nil, candidates2[2].parsed,  "Data should not have matched"
      
    # Check translations
      # regular regex
      assert_equal "Black", translations1[0][2], "Data should have matched"
      assert_equal nil, translations2[0],  "There should be no translations"

      # consecutive_fr_trans regex
      assert_equal "Noir", translations1[1][2], "Data should have matched"
      assert_equal nil, translations2[1],  "There should be no translations"

      # consecutive_order
      assert_equal "Noi", translations1[2][2], "Should have returned the first match"
      assert_equal nil, translations2[2],  "There should be no translations"
  end
end
