# Put code for getting info about (or figuring out) database issues here
# Leave a comment containing the date and a description of the problem, and whether or not the issue is resolved (you can also just delete the relevant code)

# 16/03/2012: Some categories are scraped/have products when they shouldn't
# This removes the products/specs that were scraped in the categories
task :get_rid_of_category => :environment do
  CATEGORIES_TO_DELETE = ['F29089','F32080']
  pids = CatSpec.where(:value => CATEGORIES_TO_DELETE).map(&:product_id)
  debugger
  pids.each do |pid|
  	the_cats = CatSpec.find_all_by_product_id_and_name(pid, 'product_type').map(&:value).uniq
    if the_cats.eql?(CATEGORIES_TO_DELETE) # Remove all dependents  if only categories in are those to be deleted
  		Product.find(pid).destroy
	  end
  end
  CatSpec.where(:value => CATEGORIES_TO_DELETE).map(&:destroy) # Cleanup remaining unwanted specs
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
  #debugger
  #sleep(1)
end