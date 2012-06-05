class RuleCapitalizeBrand < Customization
  @product_type = ['FDepartments','BDepartments']
  @rule_type = 'Categorical'
  @needed_features = [{CatSpec => 'brand'}]
  @exceptions = ["AGFAPHOTO","IOSAFE","IPRODRIVE","LACIE","LITEON","SKIPDR","STARTECH","ULTRASPEED"]
  # These should be exempt from the short word rule (ie: they should not be all caps)
  @small_exceptions = ["PRO","HIP"]
      
  def RuleCapitalizeBrand.compute(values, pid)
    
    specs = []
    brand = Translation.where(locale: :en, key: "cat_option.#{Session.retailer}\.brand\.#{values.first.try(:gsub,'.','-')}").first
    brand_fr = Translation.where(locale: :fr, key: "cat_option.#{Session.retailer}\.brand\.#{values.first.try(:gsub,'.','-')}").first
    
    /--- (?<brand_value>[^\n]*)/ =~ brand.try(:value)
    /--- (?<brand_fr_value>[^\n]*)/ =~ brand_fr.try(:value)

    # English/French loop
    [[brand,brand_value],[brand_fr,brand_fr_value]].each do |brand_name, brand_val|
      unless brand_name.nil?
        if brand_val == nil
          capitalized_brand = nil
        else
          capitalized_brand = brand_val.upcase.split.map do |word|
            capitalize_word(word)
          end.join(" ")
        end
        brand_name.value = "--- #{capitalized_brand}\n...\n"
        brand_name.save
      end
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