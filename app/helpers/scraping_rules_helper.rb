module ScrapingRulesHelper
  # More thorough than getting the type of only one rule (though there should not be more than one type)
  def get_feature_type (rules)
    rule_types = rules.map{|rule| rule.rule_type}.uniq
    feature_type = ""
    rule_types.each do |rule_type|
      feature_type << rule_type << " "
    end
    feature_type
  end
end
