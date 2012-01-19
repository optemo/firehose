class ChangeRuleTypeInScrapingRules < ActiveRecord::Migration
  def up
    ScrapingRule.where("rule_type = 'intr'").delete_all
    ScrapingRule.where("rule_type = 'cat'").update_all(:rule_type => "Categorical")
    ScrapingRule.where("rule_type = 'cont'").update_all(:rule_type => "Continuous")
    ScrapingRule.where("rule_type = 'bin'").update_all(:rule_type => "Binary")
    ScrapingRule.where("rule_type = 'text'").update_all(:rule_type => "Text")
  end

  def down
    ScrapingRule.where("rule_type = 'Categorical'").update_all(:rule_type => "cat")
    ScrapingRule.where("rule_type = 'Continuous'").update_all(:rule_type => "cont")
    ScrapingRule.where("rule_type = 'Binary'").update_all(:rule_type => "bin")
    ScrapingRule.where("rule_type = 'Text'").update_all(:rule_type => "text")
  end
end
