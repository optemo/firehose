desc "Enter featured products"
task :featured_products => :environment do
  require 'featured_entry'
  featured_hash = {"camera_bestbuy" => ['B9002572', 'B9002575', 'B9002576', 'B9002577', '10164411', '10173488', '10164408', '10161011', '10166499', '10156032', '10180874', '10168413', '10168343', 'B9002574'], 
                   "drive_bestbuy" => ['10179919', '10179919', '10179921', '10167004', '10159259', '10154954', '10134110', '10176410', '10160772', '10126066', '10168900'. '10174032']}
  
  featured_products(featured_hash["camera_bestbuy"], "camera_bestbuy")
  featured_products(featured_hash["drive_bestbuy"], "drive_bestbuy")
end