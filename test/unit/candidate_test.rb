require 'test_helper'

class CandidateTest < ActiveSupport::TestCase
  # Replace this with your real tests.
  test "candidates get grouped into a hierarchy" do
    sr = create(:scraping_rule, local_featurename: "hophead")
    c1 = build(:candidate, scraping_rule: sr)
    c_d = build(:candidate, scraping_rule: sr, delinquent: true)
    rules,multirules,colors = Candidate.organize([c1,c_d])
    assert_equal rules.keys, ["hophead"], "The rules should be grouped by local featurename"
    assert rules["hophead"][0].index(c_d) < rules["hophead"][0].index(c1), "Delinquents are shown before normal candidates"
    assert multirules
    assert colors
  end
  test "multirules combine scraping results according to scraping rule priority" do
    sr1 = create(:scraping_rule, remote_featurename: "hophead", local_featurename: "title", priority: 2)
    c1 = build(:candidate, scraping_rule: sr1, parsed: "hop")
    
    sr2 = create(:scraping_rule, remote_featurename: "loghead", local_featurename: "title", priority: 1)
    c2 = build(:candidate, scraping_rule: sr2, parsed: "log")
    
    rules,multirules,colors = Candidate.organize([c1,c2])
    assert_equal rules["title"], [[c2], [c1]], "The rules should be grouped by local featurename and ordered by priority"
    assert_equal multirules["title"].first, c2, "For multirules, candidates should be chosen by priority"
  end
  
  test "Colors should match all the different rules being applied" do
    sr1 = create(:scraping_rule, remote_featurename: "hophead", local_featurename: "title", priority: 2)
    c1 = build(:candidate, scraping_rule: sr1, parsed: "hop")
    
    sr2 = create(:scraping_rule, remote_featurename: "loghead", local_featurename: "title", priority: 1)
    c2 = build(:candidate, scraping_rule: sr2, parsed: "log", sku: "1010101")
    rules,multirules,colors = Candidate.organize([c1,c2])
    
    assert_equal colors[sr1.local_featurename], {sr1.id => "#4F3333", sr2.id => "green"}
  end
  
  test "Testing multi-rules" do
    sr = create(:scraping_rule, priority: 2)
    sr1 = create(:scraping_rule, priority: 1)
    c1 = build(:candidate, scraping_rule: sr)
    c2 = build(:candidate, scraping_rule: sr1)
    assert_equal [c2], Candidate.multi([c1,c2])
  end
end
