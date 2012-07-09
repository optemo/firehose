def search_for(search_type, params)
# Accesses the Amazon feed and returns 10 products and their data
# The data is split into an array and returned
  associates_id = '***REMOVED***'
  key_id = '***REMOVED***'
  is = ItemSearch.new(search_type, params)
  is.response_group = ResponseGroup.new( 'Medium', 'Images', 'ItemAttributes')
  resp = Request.new(key_id, associates_id).search( is )
  string_array = resp.item_search_response[0].to_s.gsub!("\n", '|').split('|')
end

def create_amazon_specs(item, id)
# Creates all specs for a given item
  # Create product_type (not a rule in scraping rules)
  c = CatSpec.find_or_initialize_by_product_id_and_name(id, 'product_type')
  c.update_attributes(value: item['product_type'])
  c = ContSpec.find_or_initialize_by_product_id_and_name(id, 'saleprice')
  c.update_attributes(value: item['saleprice'])
  # Get all the rules that apply to the parent category or this item's category
  for rule in ScrapingRule.find_by_sql("select * from `scraping_rules` where `product_type` in ('ADepartments', '#{item['product_type']}')")
    rule_type = CatSpec
    case rule.rule_type
    when 'Continuous'
      rule_type = ContSpec
    when 'Binary'
      rule_type = BinSpec
    when 'Text'
      rule_type = TextSpec
    end
    if item[rule.local_featurename]
      spec = rule_type.find_or_initialize_by_product_id_and_name(id, rule.local_featurename)
      spec.update_attributes(value: item[rule.local_featurename])\
    end
  end
end

def save(items)
# Uploads data for all items
  retailer = "A"
  total_items = items.length
  completed = 0
  products_to_save = []
  for item in items
    if item['title'] # Don't upload products without names
      puts "Uploading to database: #{completed*100/total_items}%"
      # Make sure not to duplicate products - check if they're already in the table
      prod = Product.find_or_initialize_by_sku_and_retailer(item['sku'], retailer)
      prod.update_attributes(instock: true)
      
      create_amazon_specs(item, Product.find_by_sku_and_retailer(item['sku'], retailer).id)
      products_to_save << prod
      completed += 1
    end
  end
  
  #Product.import products_to_update.values, :on_duplicate_key_update=>[:instock]
  
  # translations.each do |locale, key, value|
  #   I18n.backend.store_translations(locale, {key => value}, {escape: false})
  # end
  # 
  # specs_to_save.each do |s_class, v|
  #   s_class.import v, :on_duplicate_key_update=>[:product_id, :name, :value] # Bulk insert/update for efficiency
  # end
  
  puts 'running custom rules and equivalences'
  # save equivalences
  categories = ['Acamera_amazon', 'Atv_amazon', 'Amovie_amazon', 'Asoftware_amazon']
  
  categories.each do |category|
    Session.new category
    custom_specs_to_save = Customization.run(products_to_save.map(&:id))
    puts custom_specs_to_save
    custom_specs_to_save.each do |spec_class, spec_values|
      spec_class.import spec_values, :on_duplicate_key_update=>[:product_id, :name, :value]
    end
    Equivalence.fill
  end
  
  puts 'indexing products to sunspot'
  #Reindex sunspot
  puts Sunspot.search(Product).total
  
  Sunspot.index(products_to_save)
  Sunspot.commit
  
  puts Sunspot.search(Product).total
  
  puts "Save complete: #{Product.where(retailer: retailer).length} products saved"
end

def get_scraping_rules(product_type)
# Gathers all scraping rules for a given product type as well as for the parent department (in this case ADepartments)
  scraping_rules = []
  scraping_rules << ScrapingRule.where(product_type: product_type)
  scraping_rules << ScrapingRule.where(product_type: 'ADepartments')
  scraping_rules.flatten!
end

def get_real_rule(scraping_rule)
# Parses the scraping rule and extracts the regex and any additional information
  scraping_rule.gsub!(/^\//, "")
  index = scraping_rule.index(/[^\\]\//)
  if index # If the regex contains an unescaped /
    # Then extract the regex and whatever information comes after the /
    regexp = Regexp.new(scraping_rule[0..index])
    replacement = scraping_rule[index+2...scraping_rule.length]
    gsub = false
    gsub = true if replacement =~ /^\\/ # Indicates a rule that looks like this: '/(.*)(regex)(.*)/\2', one that will have partial data extracted from it later
                                        # If gsub is false it means that the rule is something more like '/regex/REPLACEMENT'
                                        # => where if the text matches the regex, the extracted data will simply be 'REPLACEMENT'
    rule = [regexp, replacement, gsub]
  else
    rule = [Regexp.new(scraping_rule)]
  end
end

def scrape(product_type, string_array)
# Uses the scraping rules to gather all data from the Amazon string array
  scraping_rules = get_scraping_rules(product_type)
  i = 0
  item_index = -1
  items = []
  while i < string_array.length
    text = string_array[i].gsub('&amp;', '&')
    
    if text =~ /asin = / || i == string_array.length-1 # If we've parsed a full item
      if item_index >= 0 # If at least one item has been parsed (we don't want to accidentally try to go to items[-1])
        # Make adjustments to the previous item
        
        items[item_index]['product_type'] = product_type
        # Fix formatting
        items[item_index]['screen_type'].upcase! if items[item_index]['screen_type'] && items[item_index]['screen_type'] !~ /plasma/i
        items[item_index]['price'] = items[item_index]['price'].to_i/100.0 if items[item_index]['price']
        items[item_index]['price_new'] = items[item_index]['price_new'].to_i/100.0 if items[item_index]['price_new']
        items[item_index]['price_used'] = items[item_index]['price_used'].to_i/100.0 if items[item_index]['price_used']
        if items[item_index]['price_new']
          items[item_index]['saleprice'] = items[item_index]['price_new']
          items[item_index]['price'] = items[item_index]['price_new'] unless items[item_index]['price']
        elsif items[item_index]['price_used']
          items[item_index]['saleprice'] = items[item_index]['price_used']
          items[item_index]['price'] = items[item_index]['price_used'] unless items[item_index]['price']
        end
        
        # Add default values where necessary
        items[item_index]['image_url_t'] = 'noimage' if items[item_index]['image_url_t'].nil?
        items[item_index]['image_url_s'] = 'noimage' if items[item_index]['image_url_s'].nil?
        items[item_index]['image_url_m'] = 'noimage' if items[item_index]['image_url_m'].nil?
        items[item_index]['image_url_l'] = 'noimage' if items[item_index]['image_url_l'].nil?
        items[item_index]['language'] = 'English' if product_type == 'Amovie_amazon' && items[item_index]['language'].nil?
        items[item_index]['app_type'] = 'software' if product_type == 'Asoftware_amazon' && items[item_index]['app_type'].nil?
        
        # Certain product types may have meaningless attributes; remove them
        if items[item_index]['title'] =~ /mount/i
          items[item_index].delete('size')
          items[item_index].delete('screen_type')
        end
      end
      if text =~ /asin = / # If there is still a product left
        items.push({})
        item_index += 1
      end
    end
    
    if item_index >= 0 # Only do this after an item has been parsed, don't want to access items[-1]
      # Run every rule on the text
      for rule in scraping_rules
        parent_rule = false
        parent_rule = true if rule.product_type == 'ADepartments'
        regex, replacement, gsub = get_real_rule(rule.regex)
        if text =~ Regexp.new(rule.remote_featurename) # If this text will contain the data the rule is looking for
          if gsub && text =~ regex # If certain data is going to be extracted
            items[item_index][rule.local_featurename] = text.gsub(regex, replacement) unless parent_rule && items[item_index][rule.local_featurename]
          elsif gsub && text.downcase =~ regex # If the above failed, we try downcasing the text because certain rules work for lower case
            items[item_index][rule.local_featurename] = text.downcase.gsub(regex, replacement) unless parent_rule && items[item_index][rule.local_featurename]
          elsif text.downcase =~ regex # If both of the above failed, just do a replacement
            items[item_index][rule.local_featurename] = replacement unless parent_rule && items[item_index][rule.local_featurename]
          end
        end
      end
    end
    
    i += 1
  end
  items
end

task :destroy_amazon_products => :environment do |t,args|
  products = Product.where(retailer: "A")
  ids = []
  for p in products
    ids << p.id
  end
  
  total = ids.length
  completed = 0
  
  for id in ids
    Product.find(id).destroy
    puts "Clearing old Amazon data: #{(completed += 1)*100/total}%"
  end
end

task :scrape_amazon_data => :environment do |t,args|
  require '/optemo/site/lib/helpers/sitespecific/amazon_scraper.rb'
  require '/optemo/firehose/app/models/scraping_rule.rb'
  require 'amazon/aws/search'
  include AmazonScraper
  
  search_params =   [
                      ['Amovie_amazon', 'Video', {'AudienceRating' => 'G'}],
                      ['Amovie_amazon', 'Video', {'AudienceRating' => 'PG'}],
                      ['Amovie_amazon', 'Video', {'AudienceRating' => 'PG-13'}],
                      ['Amovie_amazon', 'Video', {'AudienceRating' => 'R'}],
                      ['Amovie_amazon', 'Video', {'AudienceRating' => 'NC-17'}],
                      ['Amovie_amazon', 'Video', {'AudienceRating' => 'Unrated'}],
                      ['Amovie_amazon', 'Video', {'Title' => 'Lord of the Rings'}],
                      ['Amovie_amazon', 'Video', {'Title' => 'Star Wars'}],
                      ['Amovie_amazon', 'Video', {'Title' => 'Alien'}],
                      ['Amovie_amazon', 'Video', {'Title' => 'Harry Potter'}],
                      ['Amovie_amazon', 'Video', {'Title' => 'Indiana Jones'}],
                      ['Amovie_amazon', 'Video', {'Title' => 'King Kong'}],
                      ['Amovie_amazon', 'Video', {'Title' => 'Looney Toons'}],
                      ['Atv_amazon', 'Electronics', {'Manufacturer' => 'Panasonic', 'Keywords' => 'tv 1080p'}],
                      ['Atv_amazon', 'Electronics', {'Manufacturer' => 'Panasonic', 'Keywords' => 'tv 720p'}],
                      ['Atv_amazon', 'Electronics', {'Manufacturer' => 'ViewSonic', 'Keywords' => 'tv'}],
                      ['Atv_amazon', 'Electronics', {'Manufacturer' => 'Samsung', 'Keywords' => 'tv 1080p'}],
                      ['Atv_amazon', 'Electronics', {'Manufacturer' => 'Samsung', 'Keywords' => 'tv 720p'}],
                      ['Atv_amazon', 'Electronics', {'Manufacturer' => 'Toshiba', 'Keywords' => 'tv 1080p'}],
                      ['Atv_amazon', 'Electronics', {'Manufacturer' => 'Toshiba', 'Keywords' => 'tv 720p'}],
                      ['Atv_amazon', 'Electronics', {'Manufacturer' => 'Coby', 'Keywords' => 'tv 1080p'}],
                      ['Atv_amazon', 'Electronics', {'Manufacturer' => 'Coby', 'Keywords' => 'tv 720p'}],
                      ['Atv_amazon', 'Electronics', {'Manufacturer' => 'LG', 'Keywords' => 'tv'}],
                      ['Atv_amazon', 'Electronics', {'Manufacturer' => 'Sharp', 'Keywords' => 'tv'}],
                      ['Atv_amazon', 'Electronics', {'Manufacturer' => 'RCA', 'Keywords' => 'tv'}],
                      ['Atv_amazon', 'Electronics', {'Manufacturer' => 'Vizio', 'Keywords' => 'tv'}],
                      ['Acamera_amazon', 'Electronics', {'Manufacturer' => 'Sony', 'Keywords' => 'camera'}],
                      ['Acamera_amazon', 'Electronics', {'Manufacturer' => 'Samsung', 'Keywords' => 'camera'}],
                      ['Acamera_amazon', 'Electronics', {'Manufacturer' => 'Canon', 'Keywords' => 'camera'}],
                      ['Acamera_amazon', 'Electronics', {'Manufacturer' => 'Nikon', 'Keywords' => 'camera'}],
                      ['Acamera_amazon', 'Electronics', {'Manufacturer' => 'AgfaPhoto', 'Keywords' => 'camera'}],
                      ['Acamera_amazon', 'Electronics', {'Manufacturer' => 'Panasonic', 'Keywords' => 'camera'}],
                      ['Acamera_amazon', 'Electronics', {'Manufacturer' => 'Fuji', 'Keywords' => 'camera'}],
                      ['Acamera_amazon', 'Electronics', {'Manufacturer' => 'Kodak', 'Keywords' => 'camera'}],
                      ['Acamera_amazon', 'Electronics', {'Manufacturer' => 'Olympus', 'Keywords' => 'camera'}],
                      ['Acamera_amazon', 'Electronics', {'Manufacturer' => 'Polaroid', 'Keywords' => 'camera'}],
                      ['Acamera_amazon', 'Electronics', {'Manufacturer' => 'Fotodiox', 'Keywords' => 'camera'}],
                      ['Asoftware_amazon', 'Software', {'Brand' => 'Microsoft', 'Keywords' => 'Software'}],
                      ['Asoftware_amazon', 'Software', {'Brand' => 'Microsoft', 'Keywords' => 'Game'}],
                      ['Asoftware_amazon', 'Software', {'Brand' => 'Apple', 'Keywords' => 'Software'}],
                      ['Asoftware_amazon', 'Software', {'Keywords' => 'photo'}],
                      ['Asoftware_amazon', 'Software', {'Brand' => 'Activision'}],
                      ['Asoftware_amazon', 'Software', {'Brand' => '2K'}],
                      ['Asoftware_amazon', 'Software', {'Brand' => 'Adobe'}],
                      ['Asoftware_amazon', 'Software', {'Brand' => 'Rosetta'}],
                      ['Asoftware_amazon', 'Software', {'Brand' => 'Encore'}],
                      ['Asoftware_amazon', 'Software', {'Brand' => 'Communications'}]
                    ]
  
  # Wipe Amazon from the database
  Rake::Task['destroy_amazon_products'].execute
               
  items = []

  total_params = search_params.length
  completed = 0

  # Fill the items array with all search results
  for params in search_params
    puts "Downloading from Amazon: #{completed*100/total_params}%"
    (items << scrape(params[0], search_for(params[1], params[2]))).flatten!
    completed += 1
  end

  puts "Download complete: #{items.length} products returned"
  save(items)
end