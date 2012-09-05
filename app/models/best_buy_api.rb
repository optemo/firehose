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
      if Rails.env.test? && (id == "100000" || id == "100001")
        JSON.parse($bb_api_response[id])
      else
        cached_request('product',q)
      end
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
    
    def get_category(id, english = true)
      q = english ? {:lang => "en"} : {:lang => "fr"}
      q[:id] = id
      res = cached_request('category',q)
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
      id = id[0..0] if Rails.env.test? #Only check first category for testing
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
      while (page == 1 || page <= totalpages && !Rails.env.test?) #Only return one page in the test environment
        res = cached_request('search',{ :page => page, :categoryid => categoryid, :filter=> "#{filter_name}|#{filter_value}" })
        totalpages ||= res["totalPages"]
        ids += res["products"].map{|p| p["sku"]}
        page += 1
      end
      ids
    end
    
    # Gets products for given category id. It returns an array of BBproduct instances, which hold the sku and the category id.
    def category_ids(id)
      #This can accept an array or a single id
      id = [id] unless id.class == Array
      id = id[0..0] if Rails.env.test? #Only check first category for testing
      ids = []
      q = {} 
      id.each do |my_id|
        #Check if ProductType or feed_id
        my_id = ProductCategory.trim_retailer(my_id)
        # check if the category is an invalid one (no parents, but many products listed)
        feed_category = BestBuyApi.get_category(my_id)
        root_category = BestBuyApi.get_category('Departments')
        if (feed_category['productCount'] >= (0.9 * root_category['productCount']) and my_id != 'Departments')
          puts "Category " + my_id + " invalid or empty"
          return ids
        end
        page = 1
        totalpages = nil
        while (page == 1 || page <= totalpages && !Rails.env.test?) #Only return one page in the test environment
          q = {:page => page,:categoryid => my_id, :sortby => "name"}
          # add search params needed to get the EHF from QC 
          q[:currentregion]="QC"
          q[:ignoreehfdisplayrestrictions]="true"
          res = cached_request('search',q)
          totalpages ||= res["totalPages"]
          ids += res["products"].map{|p|BBproduct.new(:id => p["sku"], :category => my_id)}
          page += 1
        end
      end
      ids
    end
    
    # Gets product infos for given category id. Returns an array of hashes, one for each product in the category.
    # This uses the BestBuy 'search' API call, so it does not return all of the product info available through
    # the 'product' API call. 
    def get_shallow_product_infos(category_id, english = true)
      # Remove leading B/F/A
      category_id = ProductCategory.trim_retailer(category_id)
      if category_id != 'Departments'
        # Invalid or empty categories result in the entire catalog being returned.
        category_info = BestBuyApi.get_category(category_id)
        root_category_info = BestBuyApi.get_category('Departments')
        if category_info['productCount'] >= 0.9 * root_category_info['productCount']
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
        # Bypass the cache to return the latest information.
        result = send_request('search', query)
        total_pages = result["totalPages"]
        products.concat(result["products"])
        page += 1
      end
      products
    end
    
    def search(string,page=1)
      cached_request('search',{:page => page,:name => string})
    end
    
    def keyword_search(query)
        page = 1
        totalpages = nil
        skus = []
        while (page == 1 || page <= totalpages && !Rails.env.test?) #Only return one page in the test environment
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
