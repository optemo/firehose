# report scraping rules for which an ancestor also defines a rule for the same local_featurename
task :check_rules => :environment do
  check
end
def check
  ScrapingRule.find_each do |sr|
    product_type = sr.product_type
    others = ScrapingRule.find_all_by_product_type_and_local_featurename(ProductCategory.get_ancestors(product_type), sr.local_featurename)
    unless others.empty?
      puts 'extraneous scraping rule found:'
      pp sr
    end
  end
end

task :check_brand_capitalize => :environment do 
  require 'custom_rules/RuleCapitalizeBrand'
#  puts "Capitalized brands (all)"
#  pids = CatSpec.select(:product_id).where(:name => 'brand', :modified => nil).group("value").map(&:product_id)
#  RuleCapitalizeBrand.capitalize(pids)

  # This shouldn't save the product
  RuleCapitalizeBrand.compute_feature(["APPLE","POMME"],2)

end