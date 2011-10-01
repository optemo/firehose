desc "Enter featured products"
task :featured_products => :environment do
  require 'featured_entry'
  featured_hash = {"camera_bestbuy" => ['10164256', '10164411', '10173488', '10164409', '10154869', '10178598', '10156023', '10164962', '10164959', 'B9002152', '10164520', '10164940', '10164310'], 
                   "drive_bestbuy" => ['10166997', '10166997', '10167002', '10158177', '10167004', '10163156', '10159259', '10158365', '10176096', '10160775', '10167267', '10167617', '10174029']}

  featured_products(featured_hash["camera_bestbuy"], "camera_bestbuy")
  featured_products(featured_hash["drive_bestbuy"], "drive_bestbuy")
end