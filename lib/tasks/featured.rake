desc "Enter featured products"
task :featured_products => :environment do
  require 'featured_entry'
  featured_hash = {"camera_bestbuy" => ['B9002361', 'B9002362', '10164834', 'B9002363', '10164925', '10164976', '10164955', '10164837', '10164395', '10164527', '10164520', '10164311', '10164967', '10164406'], 
                   "drive_bestbuy" => ['10167004', '10177943', '10167002', '10158177', '10173201', '10163156', '10166997', '10174027', '10176096', '10160775', '10171551', '10167617', '10174029']}

  featured_products(featured_hash["camera_bestbuy"], "camera_bestbuy")
  featured_products(featured_hash["drive_bestbuy"], "drive_bestbuy")
end