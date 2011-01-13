class ScrapedResult
  attr_reader :rule, :products
  
  def add(rule,scraped_result)
    @rule = rule
    @products.kind_of?(Array) ? @products << scraped_result : @products = [scraped_result]
  end
end