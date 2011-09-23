desc "Enter featured products"
task :featured_products => :environment do
  require 'featured_entry'
  featured_hash = {"camera_bestbuy" => ['B9002361', 'B9002362', '10164834', 'B9002363', '10164925', '10164976', '10164955', '10164837', '10164395', '10164527', '10164520', '10164311', '10164967', '10164406'], 
                   "drive_bestbuy" => ['10174568', '10155404', '10158177', '10172168', '10166997', '10167004', '10154954', '10157927', '10155401', '10176197', '10171542', '10177444', '10169523']}

  featured_products(featured_hash["camera_bestbuy"], "camera_bestbuy")
  featured_products(featured_hash["drive_bestbuy"], "drive_bestbuy")
end