class ScrapedResult
  attr_reader :rules, :products
  def initialize
    @products = []
    @rules = []
  end
  
  def rule(priority)
    @rules[priority]
  end
  
  def add(rule,scraped_result)
    priority = rule.priority
    @rules[priority] = rule
    @products[priority].kind_of?(Array) ? @products[priority] << scraped_result : @products[priority] = [scraped_result]
  end
  
  def compact
    @rules.compact!
    @products.compact!
  end
end