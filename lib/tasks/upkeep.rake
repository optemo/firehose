#Here is where general upkeep scripts are
desc "Calculate factors for all features of all products, and pre-calculate utility scores"
task :calculate_factors => :environment do
  # Do not truncate Factor table anymore. Instead, add more factors for the given URL.
  file = YAML::load(File.open("#{Rails.root}/config/products.yml"))
  unless ENV.include?("url") && (s = Session.new(ENV["url"])) && file[ENV["url"]]
    raise "usage: rake calculate_factors url=? # url is a valid url from products.yml; sets product_type."
  end
  
  Product.calculate_factors
end



desc "Process product relationships and fill up prduct siblings table"
task :get_relations => :environment do
  file = YAML::load(File.open("#{Rails.root}/config/products.yml"))
  unless ENV.include?("url") && (Session.new(ENV["url"])) && file[ENV["url"]]
     raise "usage: rake get_relations url=? # url is a valid url from products.yml; sets product_type."
  end
  ProductSiblings.get_relations
end


desc "Set performance factors"
task :set_performance_scores => :environment do 
  file = YAML::load(File.open("#{Rails.root}/config/products.yml"))
  unless ENV.include?("url") && (s=Session.new(ENV["url"])) && file[ENV["url"]]
     raise "usage: rake set_performance_scores url=? # url is a valid url from products.yml; sets product_type."
  end
  ContSpec.delete_all(["name = ? and product_type = ?", "performance_factor", s.product_type])
  featured_skus = [10143747, 10140079, 10145495, 10141899, 10155221, 10154265, 10156451, 10142444, 10140149]
  featured_ids = Product.where(["sku IN (?)", featured_skus]).map(&:id)
  all_products = Product.valid.instock.map(&:id)
  cont_specs_records = []
  all_products.each do |p_id|
    featured_ids.include?(p_id) ? p_factor = 1 : p_factor = 0
    cont_specs_records << ContSpec.new({:product_id => p_id, :name=>"performance_factor", :value=> p_factor, :product_type=> s.product_type})   
  end
  ContSpec.transaction do 
    cont_specs_records.each(&:save)
  end 
end  