desc "Traverse the hierachy of categories from the API and store it in the database"
task :fill_categories, [:retailer_long] => :environment do |t, args|
  retailer = args.retailer_long[0]
  unless retailer == 'F' or retailer == 'B'
    puts "Wrong retailer, use F or B"
  else
    top_node = {'Departments'=>'Departments'}
    ProductCategory.update_hierarchy(top_node, retailer)
    puts "Done saving categories for "+ retailer
  end
end

