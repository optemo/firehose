desc "Enter featured products"
task :featured_products => :environment do
  require 'featured_entry'
  featured_hash = {"camera_bestbuy" => ['B9002464', '10162371', '10162508', '10162518', '10168081', 'B9002517', '10170039', '10143747', '10141718', '10164962', '10164967', '10164959', 'B9002152'], 
                   "drive_bestbuy" => ['10181185', '10167001', '10167002', '10170034', '10174460', '10159259', '10158365', '10157918', '10157919', '10160775', '10167265', '10167617', '10174029']}

  featured_products(featured_hash["camera_bestbuy"], "camera_bestbuy")
  featured_products(featured_hash["drive_bestbuy"], "drive_bestbuy")
end