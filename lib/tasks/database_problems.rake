# Put code for getting info about/figuring out/fixing database issues here
# Leave a comment containing the date and a description of the problem, and whether or not the issue is resolved (you can also just delete the relevant code)




# Some product features are scraped by different rules in En vs. Fr
# this code was not helpful in finding such products, but may be useful for something else
task :find_different_applied_rules,[:prod_cat,:local_feature] => :environment do |t,args|
  priority = 0
  results = {}
  different_prods = []
  Session.new(args.prod_cat)
  Session.product_type_leaves.each do |leaf|
    products = BestBuyApi.category_ids(leaf)
    rules = ScrapingRule.where("local_featurename = ? AND product_type = ?",args.local_feature,args.prod_cat).order("priority ASC")
    rules.each do |rule|
      # Though the priority may not match, the order is all that is important
      results[priority] = ScrapingRule.scrape(products,false,rule,false,true).last
      priority += 1
    end 
    
    # NEED TO MAKE IT SO THAT ONLY THE RULE THAT WILL BE SHOWN(ITS SCRAPED RESULT IS WHAT IS GIVEN TO THE PRODUCT) IS KEPT IN RESULTS[..]
    
    range = (0..rules.length-1)
    range.step(2) do |n|
      scraped1 = {}
      results[n].map{|cand| scraped1[cand.sku] = cand.parsed unless cand.delinquent}
      scraped2 = {}
      results[n+1].map{|cand|scraped2[cand.sku] = cand.parsed unless cand.delinquent}
      scraped1.each_pair do |sku,parsed1|
        debugger if sku =='10195222'
        # Check if only one of the parsed results is nil/unmatched
        if parsed1.nil?
          unless scraped2[sku].nil?
            different_prods.push([sku,rules[n].id])
            next
          end
        else
          if scraped2[sku].nil?
            different_prods.push([sku,rules[n].id])
            next
          end
          if parsed1 != scraped2[sku] # This will only work for rules like those for opticalDrives in laptops
            different_prods.push([sku,rules[n].id],parsed1,scraped2[sku])
            next
          end
        end
      end
    end
  end
  pp different_prods.to_s
end

# Some products are showing up in the wrong category in the site project. This could be an issue with solr indexing,
# but this is just to check that nothing is wrong with the database
task :find_misplaced_products,[:prod_cat] => :environment do |t,args|
  Session.new(args.prod_cat)
  Session.product_type_leaves.each do |leaf|
    p I18n.t("#{leaf}.name")
    ids = CatSpec.select("product_id").where("name = ? AND value = ?",'product_type',leaf)
    # Replace with spec you think would be best for checking
    rows = TextSpec.select("product_id,value").where(:product_id => ids, :name => "title")
    p "There are #{rows.length} rows"
    rows.each do |row|
      pp [row.product_id,row.value].to_s
    end
  end
end

task :find_any_missing_bundles => :environment do
  pids = BinSpec.find_all_by_name('isBundle').map(&:product_id)
  bundles = []
  no_prod_type = []
  pids.each do |pid|
    product = Product.find(pid)
    one_bundle = {:product => product, :siblings => []}
    found_bundle = false
    bundle_spec = TextSpec.find_all_by_name_and_product_id('bundle', pid)
    if bundle_spec.count > 0
      data = JSON.parse(bundle_spec.first.value.gsub("=>",":"))
      if data && !data.empty?
        
        bundle_prod_type = CatSpec.find_by_name_and_product_id("product_type", bundle_spec.first.product_id)
        no_prod_type << product if bundle_prod_type.nil?
        next if bundle_prod_type.nil?
        bundle_prod_type = bundle_prod_type.try(:value)
        data.map{|d|d["sku"]}.each do |sku|
          other_product = Product.find_by_sku_and_retailer(sku,product.retailer)
          item_prod_type = CatSpec.find_by_name_and_product_id("product_type", other_product.try(:id)).try(:value)
          unless item_prod_type.nil?
          #if bundle_prod_type == item_prod_type and !item_prod_type.nil?
            found_bundle = true
            one_bundle[:siblings] << other_product
            puts 'found bundle'
            pp one_bundle
          else
            pp 'bundle product' 
            pp product
            pp bundle_prod_type
            pp 'other product' 
            pp other_product
            pp item_prod_type
            puts '----'
          end
        end
        if found_bundle
          bundles << one_bundle
        end
      end
    end
  end
  puts 'found bundles with no product type: '
  pp no_prod_type
  puts 'and the bundles found are:'
  pp bundles
end

# 2/04/2012 Some products were deleted but productsiblings specs remained for them. deleting those
task :delete_siblings_for_invalid_pids => :environment do
  bad_siblings = ProductSibling.select{|r| !(Product.exists?(r.product_id) and Product.exists?(r.sibling_id))}
  bad_siblings.map(&:destroy)
end

# 30/03/2012 Some products were deleted but their specs remained. Taking care of that
# modified 2/04/2012 to also clear siblings and bundles for those ids
task :delete_leftover_specs => :environment do
  missing_spec = "product_type"
  pids_to_remove = [37796,72816,72820,72828,72830,72832,72834,72836,72846,72848,72868,72870,72880,72884,72886,72926,72928,72946,72950,72952,72954,72956,72960,72962,72966,72968,72996,73010,73012,73086,73088]
  pids_to_remove.each do |pid|
    if CatSpec.find_by_product_id_and_name(pid,missing_spec).nil?
      CatSpec.destroy_all(:product_id => pid)
      ContSpec.destroy_all(:product_id => pid)
      BinSpec.destroy_all(:product_id => pid)
      TextSpec.destroy_all(:product_id => pid)
      ProductSibling.destroy_all(:product_id => pid)
      ProductSibling.destroy_all(:sibling_id => pid)
      ProductBundle.destroy_all(:product_id => pid)
    else
      p "Product id: #{pid} has a #{missing_spec}"
    end
  end
#  CatSpec.destroy_all(:product_id => pids_to_remove)
#  ContSpec.destroy_all(:product_id => pids_to_remove)
#  BinSpec.destroy_all(:product_id => pids_to_remove)
#  TextSpec.destroy_all(:product_id => pids_to_remove)
end

# 28/03/2012 Some products are missing 'product_type' in cat_specs
# RESOLVED: we think that these products were deleted but not their specs (running the update task updated a new product record which has a type)
# We still don't know why they are missing the product_type, but will delete them and see if they reappear
task :find_missing_prod_type => :environment do
  missing_products = []
  all_ids = CatSpec.select("DISTINCT(product_id)").map(&:product_id)
  all_ids.each do |id|
    if CatSpec.where(:product_id => id, :name => 'product_type').empty?
      missing_products.push([id,Product.where(:id => id)])
    end
  end
  p missing_products.length
  pp missing_products
end

# 28/03/2012: Remove products scraped as a result of the accessories project (now has own database)
# Should work for other unwanted categories too ... 
# Removes products in all categories except those below
task :remove_accessory_products => :environment do 
  
  # MAKE SURE TO UPDATE THIS LIST IF YOU USE THIS TASK
  categories_wanted = ['F1127','F23773','F1002','F30659','B20218','B29157','B20352','B20232']
  p "Product Categories To Keep"
  categories_wanted.each do |category|
    Translation.where(:key => "#{category}.name").first.value =~ /--- ([^\n]+)/ 
    name = $1
    if category =~ /^F/
      p "Futureshop: #{name}"
    elsif category =~ /^B/
      p "Bestbuy: #{name}"
    else
      p "#{$1} : Unknown Retailer"
    end
  end
  p "Are these the right categories? (y/n)"
  answer = STDIN.gets.chomp
  if (answer == "y") || (answer == "yes")
    # Get all unwanted products
    leaves_wanted = []
    categories_wanted.each do |category|
      Session.new(category)
      Session.product_type_leaves.each do |leaf|
        leaves_wanted.push(leaf)
      end
    end
    all_types = CatSpec.select("DISTINCT(value)").where(:name => 'product_type').map(&:value)
    unwanted_types = all_types.keep_if{|value| !leaves_wanted.include?(value)}
    unwanted_products = Product.select("DISTINCT(products.id)").joins("INNER JOIN cat_specs ON products.id = cat_specs.product_id").where(cat_specs: {:name => 'product_type', :value => unwanted_types}).map(&:id)
    p "#{unwanted_products.length} products will be removed. Do you wish to continue? (y/n)"
    answer = STDIN.gets.chomp
    if (answer == "y") || (answer == "yes")
      Product.destroy_all(:id => unwanted_products)
    end
    
  else
    raise "Change the product types to be kept in the remove_accessory_products task"
  end
end

# 21/03/2012: Duplicates appear in siblings (same product_id and value for color)
# delete all the product siblings where the products are from different retailers
task :get_rid_of_siblings_duplicates => :environment do
  results = ProductSibling.find_by_sql 'SELECT product_id, value, count(*) FROM `product_siblings` GROUP BY product_id, value HAVING count(*) > 1'
  #records = ActiveRecord::Base.connection.execute('SELECT product_id, value, count(*) FROM `product_siblings` GROUP BY product_id, value HAVING count(*) > 1')
  results.each do |result|
    ProductSibling.find_all_by_product_id_and_value(result.product_id, result.value).each do |ps|
      if Product.find(ps.product_id).retailer != Product.find(ps.sibling_id).retailer
        ps.destroy
      end
    end
  end
end

task :find_products_with_multiple_categories => :environment do
  category_duplicates = CatSpec.find_by_sql 'SELECT product_id, name, count(*) FROM `cat_specs` GROUP BY product_id, name HAVING count(*) > 1'
  pids = results.select{|p| p.name == "product_type"}.map(&:product_id)
  products_with_problems = Product.find(results2)
  puts 'enter either category_duplicates or products_with_problems to view the problem specs and products'
  debugger
  puts 'done'
  #Product.find(results2).map(&:destroy)
end

task :throw_an_error => :environment do
  p 'about to throw an error'
  raise RuntimeError, 'an error has occurred here'
  p 'done throwing error'
end

task :get_rid_of_duplicates => :environment do
  results = Product.find_by_sql 'SELECT *, count(*) FROM `products` GROUP BY sku, retailer HAVING count(*) > 1'
  #records = ActiveRecord::Base.connection.execute('SELECT product_id, value, count(*) FROM `product_siblings` GROUP BY product_id, value HAVING count(*) > 1')
  puts 'about to delete' + result.count + ' duplicates'
  debugger
  results.each {|r| r.destroy}
end

# 22/03/2012: Some siblings appear with no colour scraped; we decided that is ok. Reporting such products here.
task :find_siblings_with_null_colour => :environment do
  results = ProductSibling.where(:value => nil)
  results.each do |result|
    pid = result.sibling_id
    colour_spec = CatSpec.find_by_product_id_and_name(pid, 'color')
    title_spec = CatSpec.find_by_product_id_and_name(pid, 'title')
    sku = Product.find_by_product_id(pid).sku
    puts sku.to_s + 'is a sibling listing null colour; color spec is: ' + colour_spec + ' title spec is: ' + title_spec
  end
end


# 16/03/2012: Some categories are scraped/have products when they shouldn't
# This removes the products/specs that were scraped in the categories
task :get_rid_of_category, [:category_name] => :environment do
  Session.new args.category_name
  CATEGORIES_TO_DELETE = Session.product_type_leaves
  pids = CatSpec.where(:value => CATEGORIES_TO_DELETE).map(&:product_id)
  debugger
  puts 'done'
  pids.each do |pid|
    the_cats = CatSpec.find_all_by_product_id_and_name(pid, 'product_type').map(&:value).uniq
    if the_cats.eql?(CATEGORIES_TO_DELETE) # Remove all dependents  if only categories in are those to be deleted
      Product.find(pid).destroy
      end
  end
end

# 14/03/2012: Certain products are present in multiple categories in the BB/FS hierarchies
# Trying to solve issue of same item in multiple categories/product_types
task :multi_cat_items,[:cat_to_find] => :environment do |t,args|
  Session.new(args.cat_to_find)
  Session.product_type_leaves.each do |leaf|
    analyze_cat_items(leaf)
  end
end

#******* RESOLVED *******#
# 19/03/2012: Not really a problem , just quick change
task :replace_orders => :environment do 
  entries = DailySpec.where(:name => 'orders')  #get all entries in table with name 'orders'
  entries.each do |entry| #iterate through and change name to 'online_orders'
    entry.update_attribute(:name, 'online_orders')
  end
end

#******* RESOLVED *******#
# 13/03/2012: Certain items were missing crucial specs
# Finds all leaf nodes in which none or some of the products do not have 'spec_name'
task :find_absent_specs,[:spec_name,:spec_type]=> :environment do |t,args|
  parent_nodes = ["B20232","B20218","B29157","F1084","F23813","F23033","F1082","F1002","F1127","F23773","F23813"]
  leaf_nodes = []
  parent_nodes.each do |cat|
    Session.new(cat)
    Session.product_type_leaves.each do |leaf|
      leaf_nodes.push(leaf)
    end
  end
  find_missing_specs(args.spec_name,args.spec_type,leaf_nodes)
end

#task :delete_unwanted_products => :environment do
#  delete_unwanted_products(['F29089','F32080'])
#end
#def delete_unwanted_products(categories)
#  pids = CatSpec.select("DISTINCT(product_id)").where(:value => categories)
#  debugger
#  pids.each do |pid|
#    # Delete the cats not wanted
#    CatSpec.select(:value).where(:name => 'product_type',:product_id => pid).each do |type|
#      if categories.include?(type)
#        debugger
#        CatSpec.delete(type.id)
#      end
#    end
#    # Delete remaining catspecs/product if no other category is tied to product
#    if CatSpec.select(:value).where(:name => 'product_type',:product_id => pid).empty?
#      debugger
#      CatSpec.delete.where(:product_id => pid)
#      debugger
#      Product.delete.where(:product_id => pid)
#    end
#  end
#end

def analyze_cat_items(cat_to_find)
  
  # Get the products in category wanted (according to feed)
  Session.new(cat_to_find)
  p "Getting products in #{cat_to_find}"
  prod_skus =  BestBuyApi.category_ids(Session.product_type) # eg output: [#<BBproduct:0x31951ec @id="M1860039", @category="29089"> ... ]
  # Find other categories in which products found
  p "Getting other categories of products in #{cat_to_find}"
  prod_cats = {}
  prod_skus.each do |prod|
    cats = CatSpec.select(:value).joins("INNER JOIN products ON products.id = cat_specs.product_id").where(products: {sku: prod.id, retailer: Session.retailer}, cat_specs: {name: 'product_type'})
    cat_ids = []
    cats.each do |cat|
      cat_ids.push(cat.value)
    end
    prod_cats[prod.id] = cat_ids
  end
  p "Analyzing data..."
  # Items only in this category
  single_cat_items = []
  prod_cats.each_pair do |prod,cats|
    if cats.length == 1
      if cats.first == cat_to_find
        single_cat_items.push(prod)
      else cats.length == 1
        p "Error: product #{prod} should have type #{cat_to_find}, not #{cats.first}"
      end
    end
  end
  # Items with multiple categories
  multi_cat_items = {}
  prod_cats.each_pair do |prod,cats|
    if cats.length > 1
      if cats.include?(cat_to_find)
        multi_cat_items[prod] = cats
      else
        p "Error: product #{prod} should have type #{cat_to_find} too"
      end
    end
  end
  # Items with repeated categories
  repeated_cat_items = {}
  multi_cat_items.each_pair do |prod,cats|
    unless cats.length == cats.uniq.length
      repeated_cat_items[prod] = cats
    end
  end
  
  # Requires scraping knowledge
  #   whether or not found on site, which page it leads to
  
  # number of items in category in question
  p "Number of items in category #{cat_to_find}: #{prod_skus.length}"
  p "Number of items only in category #{cat_to_find}: #{single_cat_items.length}"
  p "Number of items in multiple categories: #{multi_cat_items.length}"
  p "Number of items with repeated categories: #{repeated_cat_items.length}"
  debugger
  p "Available data: single_cat_items (array), multi_cat_items (hash), repeated_cat_items (hash). Otherwise, quit (q)"
  
end

#***** RESOLVED *****#
def find_missing_specs (spec_name, spec_type, leaf_nodes)
  results = {}
  case spec_type
    when "Categorical" then spec_class = CatSpec; table_name = 'cat_specs'
    when "Continuous" then spec_class = ContSpec; table_name = 'cont_specs'
    when "Binary" then spec_class = BinSpec; table_name = 'bin_specs'
    when "Text" then spec_class = TextSpec; table_name = 'text_specs'
    else p "Could not match category"
  end
  unless spec_class.nil?
    leaf_nodes.each do |leaf|
      p_ids = spec_class.select("DISTINCT(product_id)").where("name = 'product_type' AND value = '#{leaf}'")
      all_ids = []
      p_ids.each do |prod|
        all_ids.push(prod.product_id)
      end
      refined_ids = spec_class.select("DISTINCT(product_id)").where(:name => spec_name, :product_id => all_ids)
      ids = []
      refined_ids.each do |prod|
        ids.push(prod.product_id)
      end
      unless ids.length == all_ids.length
        to_store = []
        all_ids.each do |id|
          unless ids.include?(id)
            to_store.push(id)
          end
        end
      end
      results.store(leaf,["#{ids.length}/#{all_ids.length}",to_store,ids])
    end
  end
  debugger
  sleep(1)
end