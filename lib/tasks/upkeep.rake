
#Here is where general upkeep scripts are
desc "This is for testing only"
task :upkeep => :environment do
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
  #!!!!!! For testing only
#  Result.upkeep_pre
#  #Calculate new spec factors
#  Product.calculate_factors
# #Get the color relationships loaded
    ProductSibling.get_relations
#  Result.upkeep_post
end

desc "Update data automatically"
task :update => :environment do
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
  
  result = Result.new(:product_type => Session.product_type, :category => Session.category_id.to_yaml)

  result.create_from_current
  Product.create_from_result(result.id)

      # for each product_type, clean up results and related candidates days ago
      #file = YAML::load(File.open("#{Rails.root}/config/products.yml"))
      Result.cleanupByProductType(Session.product_type, 3)
  # clean up inactive scraping rules not used any more
  Feature.count_products
      ScrapingRule.cleanup
      Search.cleanup_history_data(7)
end

#Here is where general upkeep scripts are
desc "Process product relationships and fill up prduct siblings table"
task :bundles => :environment do
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

  Result.find_bundles
end

namespace :cache do
  desc 'Clear memcache'
  task :clear => :environment do
    Rails.cache.clear if Rails.cache && Rails.cache.respond_to?(:clear)
  end
end


desc "Set performance factors"
task :set_performance_scores => :environment do 
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
