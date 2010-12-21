module ScrapingHelper
  def notcovered(array)
    #Used to calculate feed coverage
    array.inject(0){|res,elem| (elem.blank? || elem == "**LOW" || elem == "**HIGH" || elem == "**Regex Error") ? res += 1 : res } || 0
  end
  
  def restrictions(rule)
    case rule.rule_type
    when "cont"
      rule.min.to_s + " - " + rule.max.to_s
    when "cat"
		  rule.valid_inputs
		else
		  "None"
	  end
  end
end
