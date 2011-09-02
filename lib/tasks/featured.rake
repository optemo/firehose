desc "Enter featured products"
task :featured_products => :environment do
  require 'featured_entry'
  featured_hash = {"camera_bestbuy" => ['10164837','10164834', '10164925', '10160766', '10165004', '10165001', '10163464', '10164410', '10173488', '10164406', '10162371', '10164435', '10162518', '10164839', '10164836', '10164927', '10160771', '10160795', '10165006', '10163469', '10164411', '10164604', '10169791', '10164408', '10164409', '10162372', '10164440', '10162519'], 
                   "drive_bestbuy" => ['10174568', '10177943', '10129570', '10155405', '10176093', '10143272', '10154954', '10158168', '10143877', '10176197', '10171551', '10171542', '10169523']}

  featured_products(featured_hash["camera_bestbuy"], "camera_bestbuy")
  featured_products(featured_hash["drive_bestbuy"], "drive_bestbuy")
end