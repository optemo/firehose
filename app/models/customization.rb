
class Customization
  require 'custom_rules/RuleBestSeller'
  require 'custom_rules/RuleComingSoon'
  require 'custom_rules/RuleNew'
  require 'custom_rules/RuleOnSale'
  require 'custom_rules/RuleUtility'
  require 'custom_rules/RuleTopViewed'
  require 'custom_rules/RuleAverageSales'
  
  class << self 
    attr_accessor :feature_name
    attr_accessor :needed_features
    attr_accessor :rule_type
    attr_accessor :product_type
  end
  
  def Customization.subclasses
    ObjectSpace.each_object(Class).select { |klass| klass < self }
  end
  
  def Customization.all
    [RuleComingSoon, RuleNew, RuleOnSale, RuleUtility, RuleBestSeller, RuleTopViewed, RuleAverageSales]
    #Customization.subclasses
  end
  
  def Customization.find_all_by_product_type(product_types)
    product_types = [product_types] unless product_types.class == Array
    Customization.all.select{ |custom_rule| !(product_types & custom_rule.product_type).empty? }
  end
  
  def Customization.rule_type_to_class(type)
    case type
      when "Categorical" then CatSpec
      when "Continuous" then ContSpec
      when "Binary" then BinSpec
      when "Text" then TextSpec
    end
  end
  
  def Customization.compute_specs(pids)
    # get all the customizations applicable to this product_type and ancestors
    rules = Customization.find_all_by_product_type(Session.product_type_path)
    results = {}
    # execute each of the rules
    rules.each do |rule|
      if (rule == RuleBestSeller || rule == RuleTopViewed || rule == RuleAverageSales)
        rule_results = rule.group_computation(pids)
      elsif rule == RuleUtility
        rule_results = RuleUtility.compute_utility(pids)
      else
        spec_features = rule.needed_features
        #spec_features = Customization.get_needed_features(rule.needed_features)
        rule_results = []
        # if an sku doesn't have a required spec value in the table, passing nil value to feature computation
        pids.each do |pid|
          values = []
          spec_features.each do |spec_feature|
            table_name = spec_feature.keys[0]
            feature_name = spec_feature.values[0]
            spec_row = table_name.find_by_product_id_and_name(pid, feature_name)
            if spec_row.nil?
              values += [nil]
            else
              values += [spec_row.value]
            end
          end
          # actual computation logic
          spec = rule.compute_feature(values, pid)
          rule_results += [spec] unless spec.nil?
        end
      end
      unless rule_results.empty?
        spec_class = rule_results[0].class
        results
        results.has_key?(spec_class) ? results[spec_class] += rule_results : results[spec_class] = rule_results
      end
    end
    results
  end
end
