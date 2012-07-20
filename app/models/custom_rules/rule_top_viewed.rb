class RuleTopViewed < Customization
  @feature_name = 'topviewed'
  @product_type = ['FDepartments','BDepartments']
  @needed_features = [{DailySpec => 'pageviews'}]
  @rule_type = 'Binary'

  def RuleTopViewed.group_computation(pids)
    
    today = Date.today # getting the weekday today
    lastFriday = Date.today - ((Date.today.wday - 5) % 7) # getting the date of the last friday, including today if friday
    
    sorted_specs = {}
    res_specs = []
    set = DailySpec.where(:name => 'pageviews', :date => (lastFriday..today)) # this set is inclusive!
    pids.each do |pid|
      prod = Product.find(pid) # will raise exception if not found
      p 'TopViewed: attempting to re-add pid' unless sorted_specs[pid].nil?
      sorted_specs[pid] = set.where(:sku => prod.sku).inject(0) {|sum, spec| sum += spec.value_flt}
    end
    
    sorted_specs = sorted_specs.sort_by {|pid, sum| sum}
    sorted_specs.reverse!
    return [] if sorted_specs.empty?
    index = (sorted_specs.count * 0.2).to_i
    threshold = sorted_specs[index][1]
    
    top_20 = sorted_specs.select{|pid,val| (val >= threshold and val > 0)}
    bottom_80 = sorted_specs.select{|pid,val| (val < threshold or val == 0)}
    spec_class = Customization.rule_type_to_class(@rule_type)
    
    top_20.each do |pid, sum|
      spec = spec_class.find_or_initialize_by_product_id_and_name(pid, @feature_name)
      spec.value = 1
      res_specs += [spec]
    end
    bottom_80.each do |pid, sum|
      prod = Product.find(pid)
      spec = spec_class.find_by_product_id_and_name(pid, @feature_name)
      spec_class.delete(spec) unless spec.nil?
    end
    res_specs
  end
end
