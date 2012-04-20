class RuleCapitalizeBrand < Customization
  @product_type = ['FDepartments','BDepartments']
  @rule_type = 'Categorical'
  @needed_features = [{CatSpec => 'brand'}]
  @exceptions = ["AGFAPHOTO","IOSAFE","IPRODRIVE","LACIE","LITEON","SKIPDR","STARTECH","ULTRASPEED"]
  # These should be exempt from the short word rule (ie: they should not be all caps)
  @small_exceptions = ["PRO","HIP"]
      
  def RuleCapitalizeBrand.compute_feature (values, pid)
    
    specs = []
    brand = Translation.where("locale = ? AND `key` REGEXP ?","en","brand.#{values.first}").first
    brand_fr = Translation.where("locale = ? AND `key` REGEXP ?","fr","brand.#{values.first}").first
    
    /--- (?<brand_value>[^\n]*)/ =~ brand.try(:value)
    /--- (?<brand_fr_value>[^\n]*)/ =~ brand_fr.try(:value)
#    debugger if brand_value == "IPRODRIVE" || brand_value == "iprodrive"
    # English brand
    unless brand.nil?
      if brand_value == nil
        capitalized_brand = nil
      else
        capitalized_brand = "" 
        brand_value.upcase.try(:split).each do |word|
          capitalized_brand << capitalize_word(word) << " "
        end
      end
      brand.value = "--- #{capitalized_brand.strip}\n...\n"
      brand.save
    end
  
    #French brand
    unless brand_fr.nil?
      if brand_fr_value == nil
        capitalized_brand = nil
      else
        capitalized_brand = "" 
        brand_fr_value.upcase.try(:split).each do |word|
          capitalized_brand << capitalize_word(word) << " "
        end
      end
      brand_fr.value = "--- #{capitalized_brand.strip}\n...\n"
      brand_fr.save
    end
    
    return nil
  end
  
  def RuleCapitalizeBrand.capitalize_word (word)
    if @exceptions.include?(word)
      new_word = case word
        when "AGFAPHOTO" then "AgfaPhoto"        
        when "IOSAFE" then "ioSafe"
        when "IPRODRIVE" then "iProDrive"
        when "LACIE" then "LaCie"
        when "LITEON" then "LiteOn"
        when "SKIPDR" then "SkipDr"
        when "STARTECH" then "StarTech"  
        when "ULTRASPEED" then "UltraSpeed"
      end
      
    elsif (/(?<punctuation>[[:punct:]])/ =~ word)
      capital_word = ""
      word.scan(/\w+[[:punct:]]|\w+\b/).each do |sub_word|
       capital_word << sub_word.capitalize
      end
      capital_word
      
    elsif (word.length > 3) || @small_exceptions.include?(word) 
      word.capitalize
      
    else #Very short words are likely acronyms, so leave them all caps.
      word
    end
  end
end