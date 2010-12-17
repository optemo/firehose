module ScrapingHelper
  def covered(array)
    #Used to calculate feed coverage
    array.inject(0){|res,elem| res += 1 if !elem.blank?}
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
