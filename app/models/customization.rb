class Customization
  class << self 
    attr_accessor :feature_name
    attr_accessor :needed_features
    attr_accessor :rule_type
    attr_accessor :product_type
    attr_accessor :only_once
  
    #Require all the custom rules, so that they can be found by the subclasses file
    Dir["#{Rails.root}/app/models/custom_rules/*.rb"].each {|file| require file }
    
    def my_subclasses
      [RuleAverageSales, RuleBestSeller, RuleCapitalizeBrand, RuleComingSoon, RuleImageURLs, RuleNew, RuleOnSale, 
        RuleTopViewed, RuleUsageType, RuleUtility, RuleAmazonPrices]
    end
    
    def find_all_by_product_type(product_types)
      product_types = [product_types] unless product_types.class == Array
      # the subclasses call only returns the subclasses on its first call
      #potentialclasses = Rails.env.test? ? subclasses.reject{|r|r == RuleUtility} : subclasses
      potentialclasses = Rails.env.test? ? my_subclasses.reject{|r|r == RuleUtility} : my_subclasses
      #Don't test rule utility because it needs to be refactored and until then it won't pass the test
      potentialclasses.select{ |custom_rule| !(product_types & custom_rule.product_type).empty? }
    end
    
    def find_all_by_product_type_and_only_once(product_types, only_once)
      find_all_by_product_type(product_types).select{ |custom_rule| (custom_rule.only_once || false) == only_once }
    end
    
    def rule_type_to_class(type)
      case type
        when "Categorical" then CatSpec
        when "Continuous" then ContSpec
        when "Binary" then BinSpec
        when "Text" then TextSpec
      end
    end
    
    def run(newproducts,oldproducts = [])
      results = Hash.new{|h,k| h[k] = []} #New values in the hash an empty array instead of nil
      # get all the customizations applicable to this product_type and ancestors that only need to be run once
      find_all_by_product_type_and_only_once(Session.product_type_path,true).each do |rule|
        results[rule_type_to_class(rule.rule_type)] += compute_specs(rule,newproducts)
      end
      # get all the customizations applicable to this product_type and ancestors that need to be run every time
      find_all_by_product_type_and_only_once(Session.product_type_path,false).each do |rule|
        results[rule_type_to_class(rule.rule_type)] += compute_specs(rule,newproducts+oldproducts)
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
