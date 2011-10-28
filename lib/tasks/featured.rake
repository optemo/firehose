desc "Enter featured products"
task :featured_products => :environment do
  require 'featured_entry'
  featured_hash = {"camera_bestbuy" => ['B9002537', 'B9002531', '10163408', '10164959', '10164410', '10178598', '10164409', '10181575', '10164955', '10179413', 'B9002534', '10164311', '10164939'], 
                   "drive_bestbuy" => ['10181185', '10179919', '10179921', '10179922', '10163156', '10166997', '10178992', '10134110', '10140784', '10160485', '10126066', '10168900', '10174032']}
  
  featured_products(featured_hash["camera_bestbuy"], "camera_bestbuy")
  featured_products(featured_hash["drive_bestbuy"], "drive_bestbuy")
end