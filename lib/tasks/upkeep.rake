#Here is where general upkeep scripts are
desc "This is for testing only"
task :upkeep => :environment do
  if !ENV.include?("product_type")
    Session.new
  else
    if /[BF]\w+/ =~ ENV["product_type"]
      Session.new ENV["product_type"]
    else
      raise "usage: rake update product_type=? # where product_type is a Bestbuy hierarchy number, e.g. B20218 or F1084."
    end
  end
  #!!!!!! For testing only
#  #Calculate new spec factors
#  Product.calculate_factors
# #Get the color relationships loaded
    ProductSibling.get_relations
end

desc "Update data automatically"
task :update => :environment do
  
  if !ENV.include?("product_type")
    Session.new
  else
    if /[BF]\w+/ =~ ENV["product_type"]
      Session.new ENV["product_type"]
    else
      raise "usage: rake update product_type=? # where product_type is a Bestbuy hierarchy number, e.g. B20218 or F1084."
    end
  end
  
  start = Time.now
  leaves = Session.product_type_leaves
  if leaves.nil? || leaves.empty?
    raise "Product type: #{ENV["product_type"]} not found"
  end

  leaves.each do |node|
    #Run the update task for this leaf node
    Session.new node
    begin 
      print 'Started scraping category ' + node.to_s
      Product.feed_update
      puts '...Finished'
    rescue BestBuyApi::RequestError => error
      puts 'Got the following error in scraping current category: '
      puts error.to_s
    end
  end
  Session.new ENV["product_type"] #Reset session
  #clean up inactive scraping rules not used any more
  Facet.check_active
  Search.cleanup_history_data(7)
  #Report problem with script if it finishes too fast
  `touch tmp/r_updateproblem.txt` if (Time.now - start < 1.minute)
end

# This task takes a product category or list of product categories as an argument.
# It determines the leaf nodes for these categories, and spawns subprocesses which 
# execute the update_leaf task for each of these leaves in parallel.
#
# Use commas to separate multiple product categories, for example:
#   rake update_parallel product_type=B20218,B29157,F1002
desc "Update product data in parallel"
task :update_parallel => :environment do
  DEFAULT_CATEGORY = "B20218"
  MAX_PARALLEL_TASKS = 3

  product_types = [DEFAULT_CATEGORY]
  
  if ENV.include?("product_type")
    product_types = ENV["product_type"].split(/,/)
  else 
    puts "update_parallel: No product_type command-line argument, using default category " + DEFAULT_CATEGORY
  end
  puts "update_parallel started at " + Time.now.to_s + ", categories = " + product_types.to_s
  
  leaves = []
  product_types.each do |type|
    some_leaves = ProductCategory.get_leaves(type)
    if some_leaves.nil? || some_leaves.empty?
      puts "No leaves found for category " + type
    else
      leaves.concat(some_leaves)
    end
  end 
  
  if leaves.empty?
    raise "No leaf nodes found for specified categories"
  end

  Rails.logger.info 'Found leaf nodes: ' + leaves.to_s

  start = Time.now
  # We first obtain the product list for each leaf category in series. Doing this step in parallel
  # seems to result in strange behavior for Best Buy's search API call.
  #
  # We store the product list for each leaf category in a temporary file and pass the path 
  # to the temp file to the child process responsible for scraping the category.
  #
  # We store temp file references in an array, to ensure they do not get garbage collected before 
  # child processes have a chance to read them (the temp files are deleted when they are garbage collected).
  temp_files = []
  curr_child_process_count = 0
  spawned_processes = 0
  leaves.each do |node|
    Session.new node
    products = Product.get_products(node)

    # Save product information to a temporary file
    temp_file = Tempfile.open("category_products", Rails.root.join('tmp')) { |temp_file|
      YAML.dump(products, temp_file)
      temp_file
    }
    temp_files << temp_file

    if curr_child_process_count >= MAX_PARALLEL_TASKS
      Process.wait
      curr_child_process_count -= 1
    end
    command_line = "bundle exec rake update_leaf product_type=#{node} file=#{temp_file.path}"
    if Rake.application.options.trace
      command_line += " --trace"
    end
    Process.spawn(command_line)
    curr_child_process_count += 1
    spawned_processes += 1
    Rails.logger.info "Spawned rake task for node " + node + " (" + spawned_processes.to_s + "/" + leaves.size.to_s + ")"
  end
                  
  Rails.logger.info "Finished spawning child processes"

  # Wait for all child processes to finish
  Process.waitall

  product_types.each do |product_type|
    Session.new product_type #Reset session
    #clean up inactive scraping rules not used any more
    Facet.check_active
  end

  Search.cleanup_history_data(7)

  #Report problem with script if it finishes too fast
  `touch tmp/r_updateproblem.txt` if (Time.now - start < 1.minute)

  puts "update_parallel finished at " + Time.now.to_s
end

# This task is not intended to be invoked directly. Instead it is invoked by 
# update_parallel for each leaf node under a category.
desc "Update data for a single leaf node"
task :update_leaf => :environment do
  
  unless ENV.include?("product_type") && ENV.include?("file")
    raise "usage: rake update_leaf product_type=? file=?"
  end
  
  node = ENV["product_type"]
  file_path = ENV["file"]

  # Force BBproduct class to be auto-loaded.
  BBproduct.new
  products = YAML.load_file(file_path)

  Session.new node
  begin 
    puts "update_leaf scraping " + products.size.to_s + " products for category " + node
    Product.feed_update(products)
    puts 'update_leaf finished scraping category ' + node
  rescue BestBuyApi::RequestError => error
    puts 'update_leaf got the following error in scraping category ' + node + ': ' + error.to_s
  end
end

namespace :cache do
  desc 'Clear memcache'
  task :clear => :environment do
    Rails.cache.clear if Rails.cache && Rails.cache.respond_to?(:clear)
  end
end


desc "Set performance factors"
task :set_performance_scores => :environment do
  exit #this code needs to be updated
  if !ENV.include?("product_type")
    Session.new
  else
    id = ProductType.find_by_name(ENV["product_type"])
    if id
      Session.new id
    else
      raise "usage: rake update product_type=? # product_type is a valid product type name from product_types table; sets product_type."
    end
  end
  begin
    # connect to the MySQL server
    dbh = Mysql2::Client.new({:host => "jaguar", :username => "opt_read", :password => "literati", :database => "piwik_09"})
  rescue Mysql2::Error => e
    puts "Error code: #{e.errno}"
    puts "Error message: #{e.error}"
    puts "Error SQLSTATE: #{e.sqlstate}" if e.respond_to?("sqlstate")
  end

  # Right now (February 7th) there aren't any results due to lack of data.
  res = dbh.query("SELECT * FROM piwik_log_preferences WHERE filter_type='addtocart' LIMIT 0,30")

  popularity_hash = {}
  total_popularity = 0

  res.each do |row|
    # We want to take each result and count how many times each product has been added to the cart.
    popularity_hash[row["product_picked"]] ? popularity_hash[row["product_picked"]] += 1 : popularity_hash[row["product_picked"]] = 1
  end

  # Sort all products by popularity in descending order.
  # Then, put a factor number in the popularity hash to replace the raw number.
  popularity_array = popularity_hash.to_a
  popularity_array.sort!{|a,b|b[1] <=> a[1]}
  popularity_array.each_with_index do |a,i| 
    # a[0] is the product id
    # set popularity_hash[a[0]] to be the result of the popularity contest
    # For example, if we have the 10th element out of 90, the factor value is 1 - 1/9 = 0.88.
    # But, if there wasn't a single add-to-cart action, the popularity factor value should stay at 0.
    popularity_hash[a[0]] = 1 - (i.to_f / popularity_array.length) unless popularity_hash[a[0]] == 0
  end

  all_products = Product.valid.instock.map(&:id)
  cont_specs_records = []
  all_products.each do |p_id|
    # If there is no value in the popularity hash, that means that it should be 0, not null.
    # This could be handled at the database level, but if it isn't, don't introduce a bug here.
    product = ContSpec.find_by_product_id_and_name_and_product_type(p_id,"performance_factor",Session.product_type)
    product ||= ContSpec.new(:product_id => p_id, :name=>"performance_factor", :product_type=> Session.product_type)   
    product.value = popularity_hash[p_id] || 0
    cont_specs_records << product
  end
  ContSpec.transaction do 
    cont_specs_records.each(&:save)
  end 
end  
