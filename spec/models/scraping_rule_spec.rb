require 'spec_helper'

describe ScrapingRule do
  before(:each) do
    @attr = {:local_featurename=>'local_test', :remote_featurename=>'remote test', :active => true, :regex=>'/\d+/', :product_type=>'camera_bestbuy', :rule_type=>'continue'}

  end

  it "should create inactive rules" do
    attr_inactive = @attr.merge(:active=>false)
    ScrapingRule.create!(attr_inactive)
    ScrapingRule.count.should be_equal(1)
  end

  it "should create 5 inactive rules" do
    attr_inactive = @attr.merge(:active=>false)
    (1..5).each do |i|
      ScrapingRule.create!(attr_inactive)
      Candidate.create!({:scraping_rule_id=>i}) if i != 5    
    end
    ScrapingRule.count.should be_equal(5)
    Candidate.count.should be_equal(4)
  end

  it "should remove inactive rules without used" do
    attr_inactive = @attr.merge(:active=>false)
    (1..5).each do |i|
      sr = ScrapingRule.create!(attr_inactive)
      Candidate.create!({:scraping_rule_id=>sr.id}) if i != 5
    end
    ScrapingRule.cleanup
    ScrapingRule.count.should be_equal(4)
    
  end
  it "should not remove active rules" do
    (1..5).each do |i|
      sr = ScrapingRule.create!(@attr)
      Candidate.create!({:scraping_rule_id=>sr.id}) if i != 5
    end

    ScrapingRule.cleanup
    ScrapingRule.count.should be_equal(5)
    
  end
end
