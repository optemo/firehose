require 'test_helper'

class ScrapingRuleTest < ActiveSupport::TestCase
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
    create :scraping_rule, local_featurename: 'regular', remote_featurename: 'specs.Physical Features.Colour', rule_type: 'Categorical', regex: 'Black|Blue|Brown' 
    create :scraping_rule, local_featurename: 'consecutive_fr_trans', remote_featurename: 'specs.Physical Features.Colour', rule_type: 'Categorical', regex: 'Pink/Rose^^Black/Noir^^Bla/Noi'
    create :scraping_rule, local_featurename: 'consecutive_order', remote_featurename: 'specs.Physical Features.Colour', rule_type: 'Categorical', regex: 'Pink/Rose^^Bla/Noi^^Black/Noir'
    
    # Call scraping on products
    candidates1 = ScrapingRule.scrape((BBproduct.new id: "100000", category: "B20218"),false,[],false) # Colour: Black
    candidates2 = ScrapingRule.scrape((BBproduct.new id: "100001", category: "B20218"),false,[],false) # Colour: Silver
    
    # Check candidates
      # regular regex
      assert_equal candidates1[0].parsed, "Black", "Data should have matched"
      assert_equal candidates2[0].parsed, nil,  "Data should not have matched"
      
      # consecutive_fr_trans regex
      assert_equal candidates1[1].parsed, "Noir", "Data should have matched"
      assert_equal candidates2[1].parsed, nil,  "Data should not have matched"
        
      # consecutive_order
      assert_equal candidates1[2].parsed, "Noi", "Should have returned the first match"
      assert_equal candidates2[2].parsed, nil,  "Data should not have matched"
  end
end
