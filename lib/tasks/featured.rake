desc "Enter featured products"
task :featured_products => :environment do
  require 'featured_entry'
  featured_hash = {"camera_bestbuy" => ['B9002301', 'B9002302', '10163289', '10163283', '10163282', '10164410', '10164411', '10164604', '10169791', '10173486', '10173487', '10173488', '10161011', '10164406', '10164408', '10164409', '10156032', 'B9002295', '10164962', '10164963', '10164965', '10163408', '10164967', '10164959', '10164960'], 
                   "drive_bestbuy" => ['10174568', '10167001', '10155404', '10158177', '10158358', '10166997', '10154954', '10143872', '10143878', '10177444', '10171542', '10177444', '10169523']}

  featured_products(featured_hash["camera_bestbuy"], "camera_bestbuy")
  featured_products(featured_hash["drive_bestbuy"], "drive_bestbuy")
end