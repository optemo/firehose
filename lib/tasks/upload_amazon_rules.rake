def destroy_amazon_rules
  puts "Deleting Amazon scraping rules..."
  rules = ScrapingRule.find_by_sql("SELECT *  FROM `scraping_rules` WHERE `product_type` REGEXP '(amazon|ADep)'")
  for rule in rules
    rule.delete
  end
  puts "Deletion complete"
end

task :upload_amazon_rules => :environment do |t, args|
  
  destroy_amazon_rules
  
  rules = []

  rules << ['title', 'title = ', '(.*title = )(.*)/\2', 'ADepartments', 'Categorical']
  rules << ['sku', 'asin = ', '(.*asin = )(.*)/\2', 'ADepartments', 'Categorical']
  rules << ['amazon_sku', 'sku = ', '(.*sku = )(.*)/\2', 'ADepartments', 'Categorical']
  rules << ['price', 'list_price = amount = ', '(.*list_price = amount = )(.*)/\2', 'ADepartments', 'Continuous']
  rules << ['price_new', 'lowest_new_price = amount = ', '(.*lowest_new_price = amount = )(.*)/\2', 'ADepartments', 'Continuous']
  rules << ['price_used', 'lowest_used_price = amount = ', '(.*lowest_used_price = amount = )(.*)/\2', 'ADepartments', 'Continuous']
  rules << ['image_url_t', 'thumbnail_image = url = ', '(.*thumbnail_image = url = )(.*)/\2', 'ADepartments', 'Text']
  rules << ['image_url_s', 'tiny_image = url = ', '(.*tiny_image = url = )(.*)/\2', 'ADepartments', 'Text']
  rules << ['image_url_m', 'medium_image = url = ', '(.*medium_image = url = )(.*)/\2', 'ADepartments', 'Text']
  rules << ['image_url_l', 'large_image = url = ', '(.*large_image = url = )(.*)/\2', 'ADepartments', 'Text']
  rules << ['brand', '(brand|publisher) = ', '(.*(brand|publisher) = )(.*)/\3', 'ADepartments', 'Categorical']
  rules << ['brand', '(brand|publisher) = ', 'new line/New Line', 'Amovie_amazon', 'Categorical']
  rules << ['brand', '(brand|publisher) = ', 'mgm/MGM', 'Amovie_amazon', 'Categorical']
  rules << ['brand', '(brand|publisher) = ', 'hgv/HGV', 'Amovie_amazon', 'Categorical']
  rules << ['brand', '(brand|publisher) = ', 'warner/Warner', 'Amovie_amazon', 'Categorical']
  rules << ['brand', '(brand|publisher) = ', 'turner/Turner', 'Amovie_amazon', 'Categorical']
  rules << ['brand', '(brand|publisher) = ', 'disney/Disney', 'Amovie_amazon', 'Categorical']
  rules << ['brand', '(brand|publisher) = ', 'buena vista/Buena Vista', 'Amovie_amazon', 'Categorical']
  rules << ['brand', '(brand|publisher) = ', 'fox/20th Century Fox', 'Amovie_amazon', 'Categorical']
  rules << ['brand', '(brand|publisher) = ', 'columbia/Columbia', 'Amovie_amazon', 'Categorical']
  rules << ['brand', '(brand|publisher) = ', 'universal/Universal', 'Amovie_amazon', 'Categorical']
  rules << ['brand', '(brand|publisher) = ', 'hbo/HBO', 'Amovie_amazon', 'Categorical']
  rules << ['brand', '(brand|publisher) = ', 'sony/Sony', 'Amovie_amazon', 'Categorical']
  rules << ['brand', '(brand|publisher) = ', 'paramount/Paramount', 'Amovie_amazon', 'Categorical']
  rules << ['brand', '(brand|publisher) = ', 'trimark/Trimark', 'Amovie_amazon', 'Categorical']
  rules << ['brand', '(brand|publisher) = ', 'sony/Sony', 'Atv_amazon', 'Categorical']
  rules << ['brand', '(brand|publisher) = ', 'viewsonic/ViewSonic', 'Atv_amazon', 'Categorical']
  rules << ['brand', '(brand|publisher) = ', 'toshiba/Toshiba', 'Atv_amazon', 'Categorical']
  rules << ['brand', '(brand|publisher) = ', 'coby/Coby', 'Atv_amazon', 'Categorical']
  rules << ['brand', '(brand|publisher) = ', 'citizen/Citizen', 'Atv_amazon', 'Categorical']
  rules << ['brand', '(brand|publisher) = ', 'samsung/Samsung', 'Atv_amazon', 'Categorical']
  rules << ['brand', '(brand|publisher) = ', 'lg/LG', 'Atv_amazon', 'Categorical']
  rules << ['brand', '(brand|publisher) = ', 'sharp/Sharp', 'Atv_amazon', 'Categorical']
  rules << ['brand', '(brand|publisher) = ', 'vizio/Vizio', 'Atv_amazon', 'Categorical']
  rules << ['brand', '(brand|publisher) = ', 'venturer/Venturer Electronics', 'Atv_amazon', 'Categorical']
  rules << ['brand', '(brand|publisher) = ', 'curtis/Curtis International', 'Atv_amazon', 'Categorical']
  rules << ['brand', '(brand|publisher) = ', 'canon/Canon', 'Acamera_amazon', 'Categorical']
  rules << ['brand', '(brand|publisher) = ', 'kodak/Kodak', 'Acamera_amazon', 'Categorical']
  rules << ['brand', '(brand|publisher) = ', 'olympus/Olympus', 'Acamera_amazon', 'Categorical']
  rules << ['brand', '(brand|publisher) = ', 'polaroid/Polaroid', 'Acamera_amazon', 'Categorical']
  rules << ['brand', '(brand|publisher) = ', 'nikon/Nikon', 'Acamera_amazon', 'Categorical']
  rules << ['brand', '(brand|publisher) = ', 'fotodiox/Fotodiox', 'Acamera_amazon', 'Categorical']
  rules << ['brand', '(brand|publisher) = ', 'agfaphoto/AgfaPhoto', 'Acamera_amazon', 'Categorical']
  rules << ['brand', '(brand|publisher) = ', 'fuji/Fuji', 'Acamera_amazon', 'Categorical']
  rules << ['brand', '(brand|publisher) = ', 'panasonic/Panasonic', 'Acamera_amazon', 'Categorical']
  rules << ['brand', '(brand|publisher) = ', 'samsung/Samsung', 'Acamera_amazon', 'Categorical']
  rules << ['brand', '(brand|publisher) = ', 'sony/Sony', 'Acamera_amazon', 'Categorical']
  rules << ['brand', '(brand|publisher) = ', 'microsoft/Microsoft', 'Asoftware_amazon', 'Categorical']
  rules << ['brand', '(brand|publisher) = ', 'apple/Apple', 'Asoftware_amazon', 'Categorical']
  rules << ['brand', '(brand|publisher) = ', 'activision/Activision', 'Asoftware_amazon', 'Categorical']
  rules << ['brand', '(brand|publisher) = ', 'adobe/Adobe', 'Asoftware_amazon', 'Categorical']
  rules << ['brand', '(brand|publisher) = ', 'skylander/Skylander', 'Asoftware_amazon', 'Categorical']
  rules << ['brand', '(brand|publisher) = ', '2k/2K', 'Asoftware_amazon', 'Categorical']
  rules << ['brand', '(brand|publisher) = ', 'nuance/Nuance Communications', 'Asoftware_amazon', 'Categorical']
  rules << ['brand', '(brand|publisher) = ', 'encore/Encore', 'Asoftware_amazon', 'Categorical']
  rules << ['title', 'title = ', '(.*title = )(.*\s\d+)([-\s][Ii]nch(es)?|\")(.*)/\2"\5', 'Atv_amazon', 'Categorical']
  rules << ['size', 'title = ', '(.*title =.*\s)(\d+)(([-\s][Ii]nch(es)?|\"|[Ii][Nn] ).*)/\2', 'Atv_amazon', 'Continuous']
  rules << ['format', 'product_group = ', '(.*product_group = )(.*)/\2', 'Amovie_amazon', 'Categorical']
  rules << ['mpaa_rating', 'audience_rating = ', '(.*audience_rating = )([\w\+-]+)(\s\(.*\))?/\2', 'Amovie_amazon', 'Categorical']
  rules << ['language', 'languages = language = name = ', '(.*languages = language = name = )(.*)/\2', 'Amovie_amazon', 'Categorical']
  rules << ['language', 'title = ', '(.*)([Ss]panish|[Ff]rench)(.*)/\2', 'Amovie_amazon', 'Categorical']
  rules << ['hdmi', 'feature = ', '[Hh][Dd][Mm][Ii]/1', 'Atv_amazon', 'Binary']
  rules << ['hdmi', 'title = ', '[Hh][Dd][Mm][Ii]/1', 'Atv_amazon', 'Binary']
  rules << ['resolution', 'title = ', '(.*)((720|1080)[IiPp])(.*)/\2', 'Atv_amazon', 'Categorical']
  rules << ['ref_rate', 'title = ', '(.*[\s,])(\d+)(\s?[Hh][Zz])(.*)/\2', 'Atv_amazon', 'Continuous']
  rules << ['3d', 'title = ', '3[-\s]?[Dd]/1', 'Atv_amazon', 'Binary']
  rules << ['screen_type', 'title = ', '(.*)([Ll][Ee][Dd]|[Ll][Cc][Dd]|[Pp][Ll][Aa][Ss][Mm][Aa])(.*)/\2', 'Atv_amazon', 'Categorical']
  rules << ['mp', 'title = ', '(.*title = .*\s)(\d+(\.\d+)?)(\s?[Mm][Pp].*)/\2', 'Acamera_amazon', 'Continous']
  rules << ['color', 'title = ', '(.*)(red|blue|green|black|gr[ae]y|yellow|purple|pink|brown|orange|white|silver)(.*)/\2', 'Acamera_amazon', 'Categorical']
  rules << ['hd_video', 'title = ', '(.*)((720|1080)[IiPp])(.*)/\2', 'Acamera_amazon', 'Categorical']
  rules << ['platform', 'platform = ', '(^platform = \[?)([^\]]*)(\]?.*)/\2', 'Asoftware_amazon', 'Categorical']
  rules << ['windows', 'platform = ', 'windows/1', 'Asoftware_amazon', 'Binary']
  rules << ['mac', 'platform = ', 'mac/1', 'Asoftware_amazon', 'Binary']
  rules << ['app_type', 'product_group = ', '[Gg]ame/video game', 'Asoftware_amazon', 'Categorical']

  puts "Creating Amazon scraping rules..."

  for rule in rules
    ScrapingRule.create(local_featurename: rule[0], remote_featurename: rule[1], regex: rule[2], product_type: rule[3], rule_type: rule[4])
  end
  
  puts "Creation complete"
end