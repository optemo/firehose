desc "Enter featured products"
task :featured_products => :environment do
  require 'featured_entry'
  featured_hash = {"camera_bestbuy" => ['B9002214','10164834', '10164836', '10164921', '10164923', '10164924', '10164935', '10164936', '10160866', '10160871', '10160895', '10164976', '10164980', '10164978', '10164837', '10164839', '10169571', '10169572', '10169573', '10168351', '10168353', '10168354', 'B9002211', 'B8002209', 'B8002210', '10173486', '10173487', '10154265'], 
                   "drive_bestbuy" => ['10174568', '10167001', '10166034', '10155405', '10143419', '10166997', '10154954', '10174027', '10176410', '10176197', '10171551', '10171542', '10169523']}

  featured_products(featured_hash["camera_bestbuy"], "camera_bestbuy")
  featured_products(featured_hash["drive_bestbuy"], "drive_bestbuy")
end