class BestBuyApi
  require 'net/http'
  class RequestError < StandardError; end
  class FeedDownError < StandardError; end
  class TimeoutError < StandardError; end
  class << self
    URL = {"B" => "http://www.bestbuy.ca/api/v2",
           "F" => "http://www.futureshop.ca/api/v2"}
    DEBUG = false
    
    #Find BestBuy products
    def product_search(id, includeall = true, english = true)
      q = english ? {} : {:lang => "fr"}
      q[:id] = id
      if includeall
        q[:include] = "all"
      end
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
      q = english ? {:lang => "en"} : {:lang => "fr"}
      q[:id] = id
      subcats = {}
      #puts "#{q}"
      res = cached_request('category',q)      
      children = res["subCategories"].inject([]){|children, sc| children << {sc["id"] => sc["name"]}}
      subcats = {{res["id"] => res["name"]} => children}
      subcats
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
        my_id = my_id.to_s[1..-1] if /^[BF]/ =~ my_id.to_s
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
    
    def category_ids(id)
      #This can accept an array or a single id
      id = [id] unless id.class == Array
      id = id[0..0] if Rails.env.test? #Only check first category for testing
      ids = []
      id.each do |my_id|
        #Check if ProductType or feed_id
        my_id = my_id.to_s[1..-1] if /^[BF]/ =~ my_id.to_s
        # check if the category is an invalid one (no parents, but many products listed)
        feed_category = BestBuyApi.get_category(my_id)
        root_category = BestBuyApi.get_category('Departments')
        
        if (feed_category['productCount'] == root_category['productCount'] and my_id != 'Departments')
          raise BestBuyApi::RequestError, ('Invalid category ' + id.to_s)
        end
        page = 1
        totalpages = nil
        while (page == 1 || page <= totalpages && !Rails.env.test?) #Only return one page in the test environment
          res = cached_request('search',{:page => page,:categoryid => my_id, :sortby => "name"})
          totalpages ||= res["totalPages"]
          ids += res["products"].map{|p|BBproduct.new(:id => p["sku"], :category => my_id)}
          page += 1
          #sleep 1 No need for waiting
        end
      end
      ids
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
      #Data is only valid for 1 hour
      CachingMemcached.cache_lookup(type + params.to_s + Session.retailer + Time.now.strftime("%Y-%m-%d-%H")) do
        send_request(type, params)
      end
    end

    # Generic send request to ECS REST service. You have to specify the :operation parameter.
    def send_request(type,params)
      request_url = prepare_url(type,params)
      #puts "#{request_url}"
      log "Request URL: #{request_url}"
      begin
        res = Net::HTTP.get_response(URI::parse(request_url))
      rescue Timeout::Error
        raise BestBuyApi::TimeoutError
      end
      #puts "#{res.body}"
      unless res.kind_of? Net::HTTPSuccess
        #if res.code == 302
        #  raise BestBuyApi::FeedDownError, "HTTP Response: #{res.code} #{res.message} for #{request_url}"
        #else
          raise BestBuyApi::RequestError, "HTTP Response: #{res.code} #{res.message} for #{request_url}"
        #end
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