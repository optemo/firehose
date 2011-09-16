desc "Enter featured products"
task :featured_products => :environment do
  require 'featured_entry'
  featured_hash = {"camera_bestbuy" => ['B9002329', 'B9002330', '10164410','10173488', '10156032', 'B9002334', 'B9002337', '10174719','10170616', 'B9002333', '10162370','10164375','10164927', '10160766', 'B9002246', 'B9002128'], 
                   "drive_bestbuy" => ['10174568', '10155404', '10158177', '10172168', '10166997', '10167004', '10154954', '10157927', '10155401', '10176197', '10171542', '10177444', '10169523']}

  featured_products(featured_hash["camera_bestbuy"], "camera_bestbuy")
  featured_products(featured_hash["drive_bestbuy"], "drive_bestbuy")
end