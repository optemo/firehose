class Customization

  class << self 
    attr_accessor :feature_name
    attr_accessor :needed_features
    attr_accessor :rule_type
    attr_accessor :product_type
  end
  
  def Customization.subclasses
    ObjectSpace.each_object(Class).select { |klass| klass < self }
  end
  
  def Customization.find_all_by_product_type(product_types)
    product_types = [product_types] unless product_types.class == Array
    Customization.subclasses.select{ |custom_rule| !(product_types & custom_rule.product_type).empty? }
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
      rule_results = []
      if rule.method_defined? :group_computation
        #Aggregate computation
        rule_results = rule.group_computation(pids)
      elsif rule.method_defined? :compute
        #Individual Computation
        spec_features = rule.needed_features
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
