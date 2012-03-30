# Put code for getting info about/figuring out/fixing database issues here
# Leave a comment containing the date and a description of the problem, and whether or not the issue is resolved (you can also just delete the relevant code)

# 28/03/2012 Some products are missing 'product_type' in cat_specs
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
  analyze_cat_items(args.cat_to_find)
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
    cat_ids = ["#{cat_to_find}"]
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