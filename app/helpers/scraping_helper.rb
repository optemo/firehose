module ScrapingHelper
  def covered(array)
    #Used to calculate feed coverage
    array.inject(0){|res,elem|elem.delinquent ? res : res+1}
  end
  
  def restrictions(rule)
    case rule.rule_type
    when "Continuous"
      rule.min.to_s + " - " + rule.max.to_s
    when "Categorical"
		  rule.valid_inputs
		else
		  "None"
	  end
  end
end
