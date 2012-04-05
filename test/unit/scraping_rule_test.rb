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
    sr1 = build(:scraping_rule, :local_featurename => "Name.withperiod")
    assert !sr1.save, "local_featurename with punctuation not allowed"
    sr1 = build(:scraping_rule, :local_featurename => "Name with spaces")
    assert !sr1.save, "local_featurename with spaces not allowed"
  end
  
  test "scraping" do
    ScrapingRule.scrape(BBproduct.new id: "100000", category: "B20218")
    assert true
  end
end
