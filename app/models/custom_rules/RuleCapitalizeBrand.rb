class RuleCapitalizeBrand < Customization
  @product_type = ['FDepartments','BDepartments']
  @rule_type = 'Categorical'
  @feature_name = 'brand'
  @needed_features = [{CatSpec => 'brand'}]
  @exceptions = ["AGFAPHOTO","IOSAFE","IPRODRIVE","LACIE","LITEON","SKIPDR","STARTECH","ULTRASPEED"]
  # These should be exempt from the short word rule (ie: they should not be all caps)
  @small_exceptions = ["PRO","HIP"]
      
  def RuleCapitalizeBrand.compute_feature (values, pid)
    capitalized_brand = "" 
    
    values.first.split.each do |word|
      capitalized_brand << capitalize_word(word) << " "
    end
    
    spec_class = Customization.rule_type_to_class(@rule_type)
    spec = spec_class.find_by_product_id_and_name(pid, @feature_name)
    spec.value = capitalized_brand
    spec
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