CONT = "Continuous"
CAT = "Categorical"
BIN = "Binary"
TEXT = "Text"
ROOT = "ADepartments"
MOVIE = "Amovie_amazon"
TV = "Atv_amazon"
CAMERA = "Acamera_amazon"
SOFTWARE = "Asoftware_amazon"

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

  rules << ['title', 'title = ', '(title = )(.*)/\2', ROOT, TEXT]
  rules << ['sku', ', asin = ', '(, asin = )(.*)/\2', ROOT, CAT]
  rules << ['amazon_sku', 'sku = ', '(sku = )(.*)/\2', ROOT, CAT]
  rules << ['price', 'list_price = amount = ', '(list_price = amount = )(.*)/\2', ROOT, CONT, 0]
  rules << ['price', 'lowest_new_price = amount = ', '(lowest_new_price = amount = )(.*)/\2', ROOT, CONT, 1]
  rules << ['price', 'offer_summary = lowest_new_price = amount = ', '(offer_summary = lowest_new_price = amount = )(.*)/\2', ROOT, CONT, 2]
  rules << ['saleprice', 'lowest_new_price = amount = ', '(lowest_new_price = amount = )(.*)/\2', ROOT, CONT, 0]
  rules << ['saleprice', 'offer_summary = lowest_new_price = amount = ', '(offer_summary = lowest_new_price = amount = )(.*)/\2', ROOT, CONT, 1]
  rules << ['saleprice', 'list_price = amount = ', '(list_price = amount = )(.*)/\2', ROOT, CONT, 2]
  #rules << ['price_new', 'lowest_new_price = amount = ', '(.*lowest_new_price = amount = )(.*)/\2', ROOT, CONT]
  #rules << ['price_used', 'lowest_used_price = amount = ', '(.*lowest_used_price = amount = )(.*)/\2', ROOT, CONT]
  rules << ['image_url_t', 'thumbnail_image = url = ', '(thumbnail_image = url = )(.*)/\2', ROOT, TEXT, 0]
  rules << ['image_url_t', 'medium_image = url = ', '(medium_image = url = )(.*)/\2', ROOT, TEXT, 1]
  rules << ['image_url_t', 'large_image = url = ', '(large_image = url = )(.*)/\2', ROOT, TEXT, 2]
  rules << ['image_url_t', 'title = ', '.*/noimage', ROOT, TEXT, 3]
  rules << ['image_url_s', 'tiny_image = url = ', '(tiny_image = url = )(.*)/\2', ROOT, TEXT, 0]
  rules << ['image_url_s', 'medium_image = url = ', '(medium_image = url = )(.*)/\2', ROOT, TEXT, 1]
  rules << ['image_url_s', 'large_image = url = ', '(large_image = url = )(.*)/\2', ROOT, TEXT, 2]
  rules << ['image_url_s', 'title = ', '.*/noimage', ROOT, TEXT, 3]
  rules << ['image_url_m', 'medium_image = url = ', '(medium_image = url = )(.*)/\2', ROOT, TEXT, 0]
  rules << ['image_url_m', 'large_image = url = ', '(large_image = url = )(.*)/\2', ROOT, TEXT, 1]
  rules << ['image_url_m', 'tiny_image = url = ', '(tiny_image = url = )(.*)/\2', ROOT, TEXT, 2]
  rules << ['image_url_m', 'title = ', '.*/noimage', ROOT, TEXT, 3]
  rules << ['image_url_l', 'large_image = url = ', '(large_image = url = )(.*)/\2', ROOT, TEXT, 0]
  rules << ['image_url_l', 'medium_image = url = ', '(medium_image = url = )(.*)/\2', ROOT, TEXT, 1]
  rules << ['image_url_l', 'tiny_image = url = ', '(tiny_image = url = )(.*)/\2', ROOT, TEXT, 2]
  rules << ['image_url_l', 'title = ', '.*/noimage', ROOT, TEXT, 3]
  rules << ['thumbnail_url', 'medium_image = url = ', '(medium_image = url = )(.*)/\2', ROOT, TEXT]
  rules << ['displayDate', 'release_date = ', '(release_date = )(\d{4})-(\d{2})-(\d{2})(.*)/\2\3\4', ROOT, CAT]
  rules << ['sales_rank', 'sales_rank = ', '(sales_rank = )(\d )(.*)/\2', ROOT, CONT]
  rules << ['brand', 'publisher = ', '[Nn][Ee][Ww] [Ll][Ii][Nn][Ee]/New Line', MOVIE, CAT, 0]
  rules << ['brand', 'publisher = ', '[Mm][Gg][Mm]/MGM', MOVIE, CAT, 2]
  rules << ['brand', 'publisher = ', '[Hh][Gg][Vv]/HGV', MOVIE, CAT, 3]
  rules << ['brand', 'publisher = ', '[Ww][Aa][Rr][Nn][Ee][Rr]/Warner', MOVIE, CAT, 4]
  rules << ['brand', 'publisher = ', '[Tt][Uu][Rr][Nn][Ee][Rr]/Turner', MOVIE, CAT, 5]
  rules << ['brand', 'publisher = ', '[Dd][Ii][Ss][Nn][Ee][Yy]/Disney', MOVIE, CAT, 6]
  rules << ['brand', 'publisher = ', '[Bb][Uu][Ee][Nn][Aa] [Vv][Ii][Ss][Tt][Aa]/Buena Vista', MOVIE, CAT, 7]
  rules << ['brand', 'publisher = ', '[Ff][Oo][Xx]/20th Century Fox', MOVIE, CAT, 8]
  rules << ['brand', 'publisher = ', '[Cc][Oo][Ll][Uu][Mm][Bb][Ii][Aa]/Columbia', MOVIE, CAT, 9]
  rules << ['brand', 'publisher = ', '[Uu][Nn][Ii][Vv][Ee][Rr][Ss][Aa][Ll]/Universal', MOVIE, CAT, 10]
  rules << ['brand', 'publisher = ', '[Hh][Bb][Oo]/HBO', MOVIE, CAT, 11]
  rules << ['brand', 'publisher = ', '[Ss][Oo][Nn][Yy]/Sony', MOVIE, CAT, 12]
  rules << ['brand', 'publisher = ', '[Pp][Aa][Rr][Aa][Mm][Oo][Uu][Nn][Tt]/Paramount', MOVIE, CAT, 13]
  rules << ['brand', 'publisher = ', '[Tt][Rr][Ii][Mm][Aa][Rr][Kk]/Trimark', MOVIE, CAT, 14]
  rules << ['brand', 'publisher = ', '[Cc]\.?\s?[Bb]\.?\s?[Ss]/CBS', MOVIE, CAT, 15]
  rules << ['brand', 'publisher = ', '(publisher = )(.*)/\2', MOVIE, CAT, 16]
  rules << ['brand', 'brand = ', '[Ss][Oo][Nn][Yy]/Sony', TV, CAT, 0]
  rules << ['brand', 'brand = ', '[Vv][Ii][Ee][Ww][Ss][Oo][Nn][Ii][Cc]/ViewSonic', TV, CAT, 1]
  rules << ['brand', 'brand = ', '[Tt][Oo][Ss][Hh][Ii][Bb][Aa]/Toshiba', TV, CAT, 2]
  rules << ['brand', 'brand = ', '[Cc][Oo][Bb][Yy]/Coby', TV, CAT, 3]
  rules << ['brand', 'brand = ', '[Cc][Ii][Tt][Ii][Zz][Ee][Nn]/Citizen', TV, CAT, 4]
  rules << ['brand', 'brand = ', '[Ss][Aa][Mm][Ss][Uu][Nn][Gg]/Samsung', TV, CAT, 5]
  rules << ['brand', 'brand = ', '[Ll][Gg]/LG', TV, CAT, 6]
  rules << ['brand', 'brand = ', '[Ss][Hh][Aa][Rr][Pp]/Sharp', TV, CAT, 7]
  rules << ['brand', 'brand = ', '[Vv][Ii][Zz][Ii][Oo]/Vizio', TV, CAT, 8]
  rules << ['brand', 'brand = ', '[Vv][Ee][Nn][Tt][Uu][Rr][Ee][Rr]/Venturer', TV, CAT, 9]
  rules << ['brand', 'brand = ', '[Cc][Uu][Rr][Tt][Ii][Ss]/Curtis', TV, CAT, 10]
  rules << ['brand', 'brand = ', '(brand = )(.*)/\2', TV, CAT, 11]
  rules << ['brand', 'brand = ', '[Cc][Aa][Nn][Oo][Nn]/Canon', CAMERA, CAT, 0]
  rules << ['brand', 'brand = ', '[Kk][Oo][Dd][Aa][Kk]/Kodak', CAMERA, CAT, 1]
  rules << ['brand', 'brand = ', '[Oo][Ll][Yy][Mm][Pp][Uu][Ss]/Olympus', CAMERA, CAT, 2]
  rules << ['brand', 'brand = ', '[Pp][Oo][Ll][Oo][Ii][Dd]/Polaroid', CAMERA, CAT, 3]
  rules << ['brand', 'brand = ', '[Nn][Ii][Kk][Oo][Nn]/Nikon', CAMERA, CAT, 4]
  rules << ['brand', 'brand = ', '[Ff][Oo][Tt][Oo][Dd][Ii][Oo][Xx]/Fotodiox', CAMERA, CAT, 5]
  rules << ['brand', 'brand = ', '[Aa][Gg][Ff][Aa][Pp][Hh][Oo][Tt][Oo]/AgfaPhoto', CAMERA, CAT, 6]
  rules << ['brand', 'brand = ', '[Ff][Uu][Jj][Ii]/Fuji', CAMERA, CAT, 7]
  rules << ['brand', 'brand = ', '[Pp][Aa][Nn][Aa][Ss][Oo][Nn][Ii][Cc]/Panasonic', CAMERA, CAT, 8]
  rules << ['brand', 'brand = ', '[Ss][Aa][Mm][Ss][Uu][Nn][Gg]/Samsung', CAMERA, CAT, 9]
  rules << ['brand', 'brand = ', '[Ss][Oo][Nn][Yy]/Sony', CAMERA, CAT, 10]
  rules << ['brand', 'brand = ', '(brand = )(.*)/\2', CAMERA, CAT, 11]
  rules << ['brand', 'brand = ', '[Mm][Ii][Cc][Rr][Oo][Ss][Oo][Ff][Tt]/Microsoft', SOFTWARE, CAT, 0]
  rules << ['brand', 'brand = ', '[Aa][Pp][Pp][Ll][Ee]/Apple', SOFTWARE, CAT, 1]
  rules << ['brand', 'brand = ', '[Aa][Cc][Tt][Ii][Vv][Ii][Ss][Ii][Oo][Nn]/Activision', SOFTWARE, CAT, 2]
  rules << ['brand', 'brand = ', '[Aa][Dd][Oo][Bb][Ee]/Adobe', SOFTWARE, CAT, 3]
  rules << ['brand', 'brand = ', '[Ss][Kk][Yy][Ll][Aa][Nn][Dd][Ee][Rr]/Skylander', SOFTWARE, CAT, 4]
  rules << ['brand', 'brand = ', '2[Kk]/2K', SOFTWARE, CAT, 5]
  rules << ['brand', 'brand = ', '[Nn][Uu][Aa][Nn][Cc][Ee]/Nuance Communications', SOFTWARE, CAT, 6]
  rules << ['brand', 'brand = ', '[Ee][Nn][Cc][Oo][Rr][Ee]/Encore', SOFTWARE, CAT, 7]
  rules << ['brand', 'brand = ', '[Ii][Nn][Dd][Ii][Vv][Ii][Dd][Uu][Aa][Ll]/Individual Software', SOFTWARE, CAT, 8]
  rules << ['brand', 'brand = ', '[Vv][Ii][Vv][Ee][Nn][Dd][Ii]/Vivendi', SOFTWARE, CAT, 8]
  rules << ['brand', 'brand = ', '(brand = )(.*)/\2', SOFTWARE, CAT, 9]
  rules << ['title', 'title = ', '(title = )(.*\s)(\d+)([-\s][Ii]n(ch)?(es)?|\")(.*)/\2 \3"\7', TV, TEXT]
  rules << ['size', 'title = ', '(title = )(.*\s)(\d+)([-\s][Ii]n(ch)?(es)?|\")(.*)/\3', TV, CONT]
  rules << ['format', 'product_group = ', '(product_group = )(.*)/\2', MOVIE, CAT]
  rules << ['mpaa_rating', 'audience_rating = ', '(audience_rating = )([\w\ -]+)(\s\(.*\))?/\2', MOVIE, CAT]
  rules << ['language', 'languages = language = name = ', '[Ss]panish/spanish^^[Ff]rench/french^^.*/english', MOVIE, CAT]
  rules << ['language', 'title = ', '[Ss]panish/spanish^^[Ff]rench/french^^.*/english', MOVIE, CAT]
  rules << ['running_time', 'running_time = ', '(running_time = )(\d+)(.*)/\2', MOVIE, CONT]
  rules << ['hdmi', 'feature = ', '[Hh][Dd][Mm][Ii]/1', TV, BIN]
  rules << ['hdmi', 'title = ', '[Hh][Dd][Mm][Ii]/1', TV, BIN]
  #rules << ['resolution', 'title = ', '(.*)((720|1080)[IiPp])(.*)/\2', TV, CAT]
  rules << ['resolution', 'title = ', '1080[Pp]/1080p^^1080[Ii]/1080i^^720[Pp]/720p^^720[Ii]/720i', TV, CAT]
  rules << ['ref_rate', 'title = ', '(.*[\s,])(\d+)(\s?[Hh][Zz])(.*)/\2', TV, CONT]
  rules << ['3d', 'title = ', '3[-\s]?[Dd]/1', TV, BIN]
  #rules << ['screen_type', 'title = ', '(.*)([Ll][Ee][Dd]|[Ll][Cc][Dd]|[Pp][Ll][Aa][Ss][Mm][Aa])(.*)/\2', TV, CAT]
  rules << ['screen_type', 'title = ', '[Ll][Cc][Dd]/LCD^^[Ll][Ee][Dd]/LED^^[Pp][Ll][Aa][Ss][Mm][Aa]/Plasma', TV, CAT]
  rules << ['mp', 'title = ', '(title = .*\s)(\d+(\.\d+)?)(\s?[Mm][Pp].*)/\2', CAMERA, CONT]
  #rules << ['color', 'title = ', '(.*)(red|blue|green|black|gr[ae]y|yellow|purple|pink|brown|orange|white|silver)(.*)/\2', CAMERA, CAT]
  rules << ['color', 'title = ', '[Rr][Ee][Dd]/red', CAMERA, CAT, 0]
  rules << ['color', 'title = ', '[Bb][Ll][Uu][Ee]($|[^Tt])/blue', CAMERA, CAT, 1]
  rules << ['color', 'title = ', '[Gg][Rr][Ee][Ee][Nn]/green', CAMERA, CAT, 2]
  rules << ['color', 'title = ', '[Bb][Ll][Aa][Cc][Kk]/black', CAMERA, CAT, 3]
  rules << ['color', 'title = ', '([Gg][Rr][AaEe][Yy]|[Ss][Ii][Ll][Vv][Ee][Rr])/silver', CAMERA, CAT, 4]
  rules << ['color', 'title = ', '[Yy][Ee][Ll][Ll][Oo][Ww]/yellow', CAMERA, CAT, 5]
  rules << ['color', 'title = ', '[Pp][Uu][Rr][Pp][Ll][Ee]/purple', CAMERA, CAT, 6]
  rules << ['color', 'title = ', '[Pp][Ii][Nn][Kk]/pink', CAMERA, CAT, 7]
  rules << ['color', 'title = ', '[Bb][Rr][Oo][Ww][Nn]/brown', CAMERA, CAT, 8]
  rules << ['color', 'title = ', '[Oo][Rr][Aa][Nn][Gg][Ee]/orange', CAMERA, CAT, 9]
  rules << ['color', 'title = ', '[Ww][Hh][Ii][Tt][Ee]/white', CAMERA, CAT, 10]
  #rules << ['hd_video', 'title = ', '(.*)((720|1080)[IiPp])(.*)/\2', CAMERA, CAT]
  rules << ['hd_video', 'title = ', '1080[Pp]/1080p^^1080[Ii]/1080i^^720[Pp]/720p^^720[Ii]/720i', CAMERA, CAT]
  #rules << ['platform', 'platform = ', '(^platform = \[?)([^\]]*)(\]?.*)/\2', SOFTWARE, CAT]
  rules << ['platform', 'platform = ', '[Ww]indows/Windows^^[Mm]ac/Mac', SOFTWARE, CAT]
  rules << ['app_type', 'product_group = ', '[Gg]ame/game^^.*/software', SOFTWARE, CAT]
  rules << ['product_type', 'product_type', '(.*)/\1', ROOT, CAT]

  puts "Creating Amazon scraping rules..."

  for rule in rules
    if rule[5]
      priority = rule[5]
    else
      priority = 0
    end
    ScrapingRule.create(local_featurename: rule[0], remote_featurename: rule[1], regex: rule[2], product_type: rule[3], rule_type: rule[4], priority: priority)
  end
  
  puts "Creation complete"
end