module ScrapingHelper
  def notcovered(array)
    #Used to calculate feed coverage
    array.inject(0){|res,elem| res += 1 if elem.blank?} || 0
  end
  
  def restrictions(rule)
    case rule.rule_type
    when "cont"
      r.min + " - " + r.max
    when "cat"
		  r.valid_inputs
		else
		  "None"
	  end
  end
end
