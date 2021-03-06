class RuleTemplate < Customization
  @feature_name = 'rule_template' #The name of the feature in the database
  @product_type = ['BNoDepartments'] #What categories is this rule applicable to
  @needed_features = [{CatSpec => 'displayDate'}, {CatSpec => 'preorderReleaseDate'}] #This is data required for this computation
  @rule_type = 'Binary' #Type of the feature defines which db table to put this in
  @only_once = true #This rule should only be run once on a product, as opposed to every time update is run
  @include_in_shallow_update = false # By default, custom rules are not included in the shallow update, but this can 
                                     # be overridden on a per-rule basis. Note that not all specs are included in the shallow product
                                     # info, and we do not retrieve French product info in the shallow update.

  #Pick one of the following to define depending on what type of rule is being created
  
  # Use the individual computation method if the customization can be computed one at a time
  #def RuleName.compute(values, pid)
  #  puts pid
  #  puts values
  #end
  
  # Use the group computation method when some calculation needs to be done on all the values
  #def RuleName.group_computation(pids)
  #  puts "#{pids.min}-#{pids.max}"
  #  pids.each do |pid|
  #    puts pid
  #  end
  #end
end
