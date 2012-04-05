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

task :check_appropriate_scraped => :environment do
  cats_to_check = ["B20218","B29157","B20352","B20232","F1127","F23773","F1002","F30659"]
  spec_types = {"Binary"=>BinSpec, "Categorical"=>CatSpec, "Continuous"=>ContSpec, "Text"=>TextSpec}
    
  file = File.new("/Users/marc/Documents/scraping_rule_counts.txt")
  File.open(file, "w") do |f|
    
    cats_to_check.each do |cat|
      
      Session.new(cat)
      leaves = Session.product_type_leaves
      pids = CatSpec.where(:name=>'product_type', :value=>leaves).map(&:product_id)
      
      f.puts "\n\n#{cat}:"
      spec_types.each_pair do |type_str,type|
        
        f.puts "\n\t#{type_str} Features"
        specs = ScrapingRule.select("DISTINCT(local_featurename)").where("product_type = ? AND rule_type = ?",cat,type_str).map(&:local_featurename)
        
        if type_str == "Text"
          specs.each do |spec|
            type.select("value, count(value) AS count").where(:name=>spec, :product_id=>pids).group("value HAVING count(value)>5").each do |scraped|
              f.puts "\n\t\t#{spec.ljust(30,'.')}#{scraped.value.to_s.ljust(60,'.')}#{scraped.count.to_s}"
            end
          end
        else  
          specs.each do |spec|
            type.select("value, count(value) AS count").where(:name=>spec, :product_id=>pids).group("value HAVING count(value)>1").each do |scraped|
              f.puts "\t\t#{spec.ljust(30,'.')}#{scraped.value.to_s.ljust(60,'.')}#{scraped.count.to_s}"
            end
          end
        end
      end
    end
  end
end