class AmazonApi
  SEARCH_PARAMS = { 'Amovie_amazon' =>    [
                                            ['Video', {'AudienceRating' => 'G'}],
                                            ['Video', {'AudienceRating' => 'PG'}],
                                            ['Video', {'AudienceRating' => 'PG-13'}],
                                            ['Video', {'AudienceRating' => 'R'}],
                                            ['Video', {'AudienceRating' => 'NC-17'}],
                                            ['Video', {'AudienceRating' => 'Unrated'}],
                                            ['Video', {'Title' => 'Lord of the Rings'}],
                                            ['Video', {'Title' => 'Star Wars'}],
                                            ['Video', {'Title' => 'Alien'}],
                                            ['Video', {'Title' => 'Harry Potter'}],
                                            ['Video', {'Title' => 'Indiana Jones'}],
                                            ['Video', {'Title' => 'King Kong'}],
                                            ['Video', {'Title' => 'Looney Toons'}]
                                          ],
                    'Atv_amazon' =>       [
                                            ['Electronics', {'Manufacturer' => 'Panasonic', 'Keywords' => 'tv 1080p'}],
                                            ['Electronics', {'Manufacturer' => 'Panasonic', 'Keywords' => 'tv 720p'}],
                                            ['Electronics', {'Manufacturer' => 'ViewSonic', 'Keywords' => 'tv'}],
                                            ['Electronics', {'Manufacturer' => 'Samsung', 'Keywords' => 'tv 1080p'}],
                                            ['Electronics', {'Manufacturer' => 'Samsung', 'Keywords' => 'tv 720p'}],
                                            ['Electronics', {'Manufacturer' => 'Toshiba', 'Keywords' => 'tv 1080p'}],
                                            ['Electronics', {'Manufacturer' => 'Toshiba', 'Keywords' => 'tv 720p'}],
                                            ['Electronics', {'Manufacturer' => 'Coby', 'Keywords' => 'tv 1080p'}],
                                            ['Electronics', {'Manufacturer' => 'Coby', 'Keywords' => 'tv 720p'}],
                                            ['Electronics', {'Manufacturer' => 'LG', 'Keywords' => 'tv'}],
                                            ['Electronics', {'Manufacturer' => 'Sharp', 'Keywords' => 'tv'}],
                                            ['Electronics', {'Manufacturer' => 'RCA', 'Keywords' => 'tv'}],
                                            ['Electronics', {'Manufacturer' => 'Vizio', 'Keywords' => 'tv'}]
                                          ],
                    'Acamera_amazon' =>   [
                                            ['Electronics', {'Manufacturer' => 'Sony', 'Keywords' => 'camera'}],
                                            ['Electronics', {'Manufacturer' => 'Samsung', 'Keywords' => 'camera'}],
                                            ['Electronics', {'Manufacturer' => 'Canon', 'Keywords' => 'camera'}],
                                            ['Electronics', {'Manufacturer' => 'Nikon', 'Keywords' => 'camera'}],
                                            ['Electronics', {'Manufacturer' => 'AgfaPhoto', 'Keywords' => 'camera'}],
                                            ['Electronics', {'Manufacturer' => 'Panasonic', 'Keywords' => 'camera'}],
                                            ['Electronics', {'Manufacturer' => 'Fuji', 'Keywords' => 'camera'}],
                                            ['Electronics', {'Manufacturer' => 'Kodak', 'Keywords' => 'camera'}],
                                            ['Electronics', {'Manufacturer' => 'Olympus', 'Keywords' => 'camera'}],
                                            ['Electronics', {'Manufacturer' => 'Polaroid', 'Keywords' => 'camera'}],
                                            ['Electronics', {'Manufacturer' => 'Fotodiox', 'Keywords' => 'camera'}],
                                          ],
                    'Asoftware_amazon' => [
                                            ['Software', {'Brand' => 'Microsoft', 'Keywords' => 'Software'}],
                                            ['Software', {'Brand' => 'Microsoft', 'Keywords' => 'Game'}],
                                            ['Software', {'Brand' => 'Apple', 'Keywords' => 'Software'}],
                                            ['Software', {'Keywords' => 'photo'}],
                                            ['Software', {'Brand' => 'Activision'}],
                                            ['Software', {'Brand' => '2K'}],
                                            ['Software', {'Brand' => 'Adobe'}],
                                            ['Software', {'Brand' => 'Rosetta'}],
                                            ['Software', {'Brand' => 'Encore'}],
                                            ['Software', {'Brand' => 'Communications'}]
                                          ]
                  }
  
  def self.get_all_products( category )
  # Gets all products based on the SEARCH_PARAMS constant
    all_product_data = {'data' => [], 'ids' => []}
    if category == "ADepartments"
      params = SEARCH_PARAMS['Amovie_amazon'] + SEARCH_PARAMS['Atv_amazon'] + SEARCH_PARAMS['Acamera_amazon'] + SEARCH_PARAMS['Asoftware_amazon']
    else
      params = SEARCH_PARAMS[category]
    end
    total_searches = params.length
    completed_searches = 0
    for param in params
      (all_product_data['data'] << search_for(param[0], param[1])).flatten!
      completed_searches += 1
      print "["
      i = 0
      while i < completed_searches*100/total_searches
        print "#"
        i += 1
      end
      while i < 100
        print " "
        i += 1
      end
      print "]\r"
    end
    print "\n"
    
    for element in all_product_data['data']
      if element =~ /, asin = /
        all_product_data['ids'] << BBproduct.new(id: element.gsub(/(, asin = )(.*)/, '\2'), category: Session.product_type)
      end
    end
    all_product_data
  end
  
  def self.product_search( sku, all_product_data )
    product_data = {}
    getting_data = false # True once the SKU has been found, false after there is no more product data (i.e. the iterator reaches a new product)
    for element in all_product_data
      if element.include?(sku)
        getting_data = true
        next
      end
      if getting_data
        break if element =~ /, asin = / # Onto a new product
        remote_featurename = element.gsub(/(.*= )[^=]+$/, '\1')
        product_data[remote_featurename] = element.gsub('&amp;', '&')
      end
    end
    product_data['product_type'] = Session.product_type
    product_data = nil unless product_data['lowest_new_price = amount = '] || product_data['offer_summary = lowest_new_price = amount = '] ||
                              product_data['list_price = amount = ']
    product_data
  end
  
  private
  def self.search_for(search_type, params)
  # Accesses the Amazon feed and returns 10 products and their data
  # The data is split into an array and returned
    require 'amazon/aws/search'
    include Amazon::AWS
    include Amazon::AWS::Search
    associates_id = '***REMOVED***'
    key_id = '***REMOVED***'
    is = ItemSearch.new(search_type, params)
    is.response_group = ResponseGroup.new( 'Medium', 'Images', 'ItemAttributes')
    resp = Request.new(key_id, associates_id).search( is )
    string_array = resp.item_search_response[0].to_s.gsub!("\n", '|').split('|')
  end
end
