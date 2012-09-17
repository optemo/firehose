# This class is a wrapper around the Best Buy REST API. 
# The wrapper takes care of performing necessary retries when errors occur calling the BestBuy API.
# Clients of this class should not have to implement their own retry logic.
class BestBuyApi
  require 'net/http'
  require 'remote_util'
  class RequestError < StandardError; end
  # HTTP 500 errors from BestBuy can sometimes be resolved by retrying.
  # Therefore we throw a special exception for these cases.
  class InternalServerError < RequestError; end
  class FeedDownError < StandardError; end
  class TimeoutError < StandardError; end
  class InvalidFeedError < StandardError; end

  MIN_PROTECTED_CAT_SIZE = 4 # Categories of this size or greater are protected from empty feeds.

  class << self
    URL = {"B" => "http://www.bestbuy.ca/api/v2",
           "F" => "http://www.futureshop.ca/api/v2",
          }
    DEBUG = false

    # Get BestBuy product info, given product SKU.
    # This method first attempts to retrieve all product attributes. If that fails,
    # it then attempts to retrieve just the basic product attributes.
    def get_product_info(sku, english)
      begin
        product_search(sku, true, english)
      rescue RequestError
        # Try again, without requesting extra info
        begin
          product_search(sku, false, english)
        rescue RequestError
          puts 'Error in the feed: returning nil for ' + sku
          nil
        end
      end
    end
 
    # Get BestBuy product info, given product SKU.
    def product_search(id, includeall = true, english = true)
      q = english ? {} : {:lang => "fr"}
      q[:id] = id
      if includeall
        q[:include] = "all"
      end
      q[:currentregion]="QC"
      q[:ignoreehfdisplayrestrictions]="true"

      cached_request('product',q)

      # From the BestBuy API documentation, use &Include=media and/or any of the following: 
      # relations,description,availability,all (in comma-separated format as a URL parameter)
    end
    
    def product_reviews(id)
      cached_request('reviews',{:id=>id})
    end
    
    #Search through the  Categories
    def category_search(id)
      cached_request('category',{:id => id})
    end
    
    def get_subcategories(id, english = true)
      unless Session.retailer == 'A'
        q = english ? {:lang => "en"} : {:lang => "fr"}
        q[:id] = id
        subcats = {}
        #puts "#{q}"
        res = cached_request('category',q)      
        children = res["subCategories"].inject([]){|children, sc| children << {sc["id"] => sc["name"]}}
        subcats = {{res["id"] => res["name"]} => children}
        subcats
      else
        if id =~ /Departments/
          subcats = {  {'Departments' => 'Departments'} =>
                      [ {'movie_amazon' => 'movie_amazon'},
                        {'tv_amazon' => 'tv_amazon'},
                        {'camera_amazon' => 'camera_amazon'},
                        {'software_amazon' => 'software_amazon'}
                      ]
                    }
        else
          subcats = { {id => id} => nil }
        end
        subcats
      end
    end
    
    def get_category(id, english = true, use_cache = true)
      q = english ? {:lang => "en"} : {:lang => "fr"}
      q[:id] = id
      res = use_cache ? cached_request('category', q) : send_request('category', q)
      res
    end
    
    def get_tree(root_id, english = true)
      q = english ? {:lang => "en"} : {:lang => "fr"}
      q[:id] = root_id
      
      #cats = {}
      
      subcats = {}
      
      res = cached_request('category',q)
      
      children = res["subCategories"].inject([]){|children, sc| children << {sc["id"] => sc["name"]}}
      
      # if children is empty, return nil
      children.each do |child|
        child_id = child.first.first
        child_name = child.first.last
        # puts child_name
        get_tree(child_id)
      end
      
      # for each child, call get_tree to get its children structure and then add the result to this tree, then return 
      # this tree
      subcats = {{res["id"] => res["name"]} => children}
    end
    
    #Find all the products in a category
    def listing(id,page=1)
      cached_request('search',{:page => page, :categoryid => id})
    end
    
    def some_ids(id,num = 10)
      #This can accept an array or a single id
      id = [id] unless id.class == Array
      ids = []
      id.each do |my_id|
        #Check if ProductType or feed_id
        my_id = ProductCategory.trim_retailer(my_id)
        res = cached_request('search',{:page => 1,:categoryid => my_id, :sortby => "name", :pagesize => num})
        ids += res["products"].map{|p|BBproduct.new(:id => p["sku"], :category => my_id)}
      end
       #puts "#{ids.to_s}"
       ids
    end
    
    def get_filter_values(categoryid, filter_name, language='en')
      # search url will be like this: "http://www.futureshop.ca/api/v2/json/search?categoryid=#{categoryid}&include=facets"
      result = cached_request('search', {:categoryid => categoryid, :include => 'facets', :lang => language})
      values = result["facets"].select{|p| p['name'] == filter_name}
      unless values.empty?
        return values.first['filters'].map{|r| r['name']}
      else
        raise 'Filter not found'
      end
    end
    
    def search_with_filter(categoryid, filter_name, filter_value)
      # check if category id (?)
      # e.g. request_url = prepare_url('search', params={:categoryid=>'1002',:filter=>"Usage Type|On the Go"})
      
      page = 1
      totalpages = nil
      ids = []
      while (page == 1 || page <= totalpages)
        res = cached_request('search',{ :page => page, :categoryid => categoryid, :filter=> "#{filter_name}|#{filter_value}" })
        totalpages ||= res["totalPages"]
        ids += res["products"].map{|p| p["sku"]}
        page += 1
      end
      ids
    end
    
    # Gets products for given category ids. It returns an array of BBproduct instances, which hold the sku and the category id.
    def category_ids(categories)
      #This can accept an array or a single id
      categories = [categories] unless categories.class == Array
      bb_products = []
      categories.each do |category|
        category = ProductCategory.trim_retailer(category)
        product_infos = get_shallow_product_infos(category, english = true, use_cache = true)
        bb_products += product_infos.map{ |p| BBproduct.new(:id => p["sku"], :category => category) }
      end
      bb_products
    end
    
    # Gets product infos for given category id. Returns an array of hashes, one for each product in the category.
    # This uses the BestBuy 'search' API call, so it does not return all of the product info available through
    # the 'product' API call. 
    def get_shallow_product_infos(category_id, english = true, use_cache = false)
      # Remove leading B/F/A
      category_id = ProductCategory.trim_retailer(category_id)
      category_info = BestBuyApi.get_category(category_id, true, use_cache)
      category_product_count = category_info['productCount']
      if category_id != 'Departments'
        # Invalid or empty categories can result in the entire catalog being returned.
        root_category_info = BestBuyApi.get_category('Departments')
        if category_product_count >= 0.9 * root_category_info['productCount']
          puts "Category " + category_id + " invalid or empty"
          return []
        end
      end
      products = []
      page = 1
      total_pages = 1
      query = {categoryid: category_id, sortby: "name", lang: (english ? "en" : "fr"),
               currentregion: "QC", ignoreehfdisplayrestrictions: "true"}
      while (page <= total_pages)
        query[:page] = page
        result = use_cache ? cached_request('search', query) : send_request('search', query)
        total_pages = result["totalPages"]
        products.concat(result["products"])
        page += 1
      end
      # Sometimes empty categories have category_product_count equal to 0 or 1, while the search returns many more 
      # "bogus" products from other categories.
      if products.size >= MIN_PROTECTED_CAT_SIZE and category_product_count <= 0.25 * products.size
        raise InvalidFeedError, "Search returned #{products.size} products, while category size is #{category_product_count}"
      end
      products
    end
    
    def search(string,page=1)
      cached_request('search',{:page => page,:name => string})
    end
    
    def keyword_search(query, max_returned_pages = nil)
        page = 1
        totalpages = nil
        skus = []
        while (page == 1 || (page <= totalpages && (max_returned_pages == nil || page <= max_returned_pages)))
          res = cached_request('search',{:page => page,:query => query, :sortby => "name", :pagesize=> 100})
          totalpages ||= res["totalPages"]
          skus += res["products"].inject([]){|sks, ele| sks << ele["sku"] }
          page += 1
        end
      skus
    end

    def cached_request(type, params = {})
      CachingMemcached.cache_lookup(type + params.to_s + Session.retailer + Time.now.strftime("%Y-%m-%d-%H")) do
        send_request(type, params)
      end
    end

    # Generic send request to ECS REST service. You have to specify the :operation parameter.
    def send_request(type,params)
      request_url = prepare_url(type,params)
      log "Request URL: #{request_url}"
      res = nil
      RemoteUtil.do_with_retry(exceptions: [TimeoutError, InternalServerError]) do |except|
        begin
          if not except.nil?
            puts "Error calling BestBuy API, will retry: " + except.to_s
          end
          res = Net::HTTP.get_response(URI::parse(request_url))
        rescue Timeout::Error
          raise BestBuyApi::TimeoutError, "Timeout calling #{request_url}"
        end
        if res.kind_of? Net::HTTPSuccess
          # Successful HTTP result.
        elsif res.kind_of? Net::HTTPInternalServerError
          raise BestBuyApi::InternalServerError, "HTTP Response: #{res.code} #{res.message} for #{request_url}"
        else
          raise BestBuyApi::RequestError, "HTTP Response: #{res.code} #{res.message} for #{request_url}"
        end
      end
      begin
        JSON.parse(res.body)
      rescue JSON::ParserError
        raise BestBuyApi::RequestError, "Bad Response: JSON Parser Error for #{request_url}"
      end
      
    end
    
    protected
      def log(s)
        return unless DEBUG
        if defined? Rails.logger
          Rails.logger.error(s)
        elsif defined? LOGGER
          LOGGER.error(s)
        else
          puts s
        end
      end
      
    private 
      def prepare_url(type, params)
        qs = '' #options
        qf = '' #filters
        sf = '' #store filters
        params.each {|k,v|
          next unless v && k != :id
          v = v.join(',') if v.is_a? Array
          qs << "&#{k.to_s}=#{URI.encode(v.to_s)}"
        }
        url = URL[Session.retailer]
        raise RequestError, "Base url not specified for retailer: #{Session.retailer}" if url.blank?
        if params[:id]
            "#{url}/json/#{type}/#{params[:id]}?#{qs}"
        else
            "#{url}/json/#{type}?#{qs}"
        end
      end
   end
end
