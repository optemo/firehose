desc "Enter featured products"
task :featured_products => :environment do
  require 'featured_entry'
  featured_hash = {"camera_bestbuy" => ['B9002434', '10162708', '10164411', '10163282', '10164925', '10160766', '10164955', '10168417', '10174723', '10169573', '10170616', '10164938', '10164310', 'B9002406', 'B9002244'], 
                   "drive_bestbuy" => ['10181185', '10167001', '10167002', '10170034', '10174460', '10159259', '10158365', '10157918', '10157919', '10160775', '10167265', '10167617', '10174029']}

  featured_products(featured_hash["camera_bestbuy"], "camera_bestbuy")
  featured_products(featured_hash["drive_bestbuy"], "drive_bestbuy")
end