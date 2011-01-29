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
  unless ENV.include?("url") && (s = Session.new(ENV["url"])) && file[ENV["url"]]
     raise "usage: rake get_relations url=? # url is a valid url from products.yml; sets product_type."
  end
  
  ProductSiblings.get_relations
end