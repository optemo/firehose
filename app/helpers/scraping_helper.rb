module ScrapingHelper
  def covered(array)
    #Used to calculate feed coverage
    array.inject(0){|res,elem| (elem.blank? || elem == "**LOW" || elem == "**HIGH" || elem == "**Regex Error") ? res : res += 1 } || 0
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
