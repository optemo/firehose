class Customization
  class << self 
    attr_accessor :feature_name
    attr_accessor :needed_features
    attr_accessor :rule_type
    attr_accessor :product_type
    attr_accessor :only_once
    attr_accessor :include_in_shallow_update
  
    #Require all the custom rules, so that they can be found by the subclasses file
    Dir["#{Rails.root}/app/models/custom_rules/*.rb"].each {|file| require file }
    
    def my_subclasses
      [RuleAverageSales, RuleBestSeller, RuleCapitalizeBrand, RuleComingSoon, RuleImageURLs, RuleNew, RuleOnSale, 
        RulePriceplusehf, RuleTopViewed, RuleUsageType, RuleUtility, RuleAmazonPrices]
    end
    
    def find_all_by_product_type(product_types, is_shallow_update = false)
      product_types = [product_types] unless product_types.class == Array
      potentialclasses = my_subclasses.select{ |custom_rule| !(product_types & custom_rule.product_type).empty? }
      if is_shallow_update 
        potentialclasses = potentialclasses.select{ |custom_rule| custom_rule.include_in_shallow_update }
      end
      potentialclasses
    end
    
    def find_all_by_product_type_and_only_once(product_types, only_once, is_shallow_update = false)
      find_all_by_product_type(product_types, is_shallow_update).select{ |custom_rule| (custom_rule.only_once || false) == only_once }
    end
    
    def rule_type_to_class(type)
      case type
        when "Categorical" then CatSpec
        when "Continuous" then ContSpec
        when "Binary" then BinSpec
        when "Text" then TextSpec
      end
    end
    
    def run(newproducts,oldproducts = [],is_shallow_update = false)
      results = Hash.new{|h,k| h[k] = []} #New values in the hash an empty array instead of nil
      # get all the customizations applicable to this product_type and ancestors that only need to be run once
      find_all_by_product_type_and_only_once(Session.product_type_path,true,is_shallow_update).each do |rule|
        begin
          results[rule_type_to_class(rule.rule_type)] += compute_specs(rule,newproducts)
        rescue StandardError => except
          puts "Customization rule #{rule} for product type #{Session.product_type} raised exception: #{except}"
        end
      end
      # get all the customizations applicable to this product_type and ancestors that need to be run every time
      find_all_by_product_type_and_only_once(Session.product_type_path,false,is_shallow_update).each do |rule|
        begin
          results[rule_type_to_class(rule.rule_type)] += compute_specs(rule,newproducts+oldproducts)
        rescue StandardError => except
          puts "Customization rule #{rule} for product type #{Session.product_type} raised exception: #{except}"
        end
      end
      results
    end
  
    def compute_specs(rule,pids)
      if rule.singleton_class.method_defined? :group_computation
        #Aggregate computation
        rule.group_computation(pids)
      elsif rule.singleton_class.method_defined? :compute
        #Individual Computation
        spec_features = rule.needed_features
        rule_results = []
        pids.each do |pid|
          values = []
          (spec_features || []).each do |spec_feature|
            table_name = spec_feature.keys[0]
            feature_name = spec_feature.values[0]
            spec_row = table_name.find_by_product_id_and_name(pid, feature_name)
            values += [spec_row.try(:value)]
          end
          # actual computation logic
          spec = rule.compute(values, pid)
          rule_results += [spec].flatten unless spec.nil?
        end
        rule_results
      else
        [] #Empty array because there is no method defined
      end
    end
  end
end
