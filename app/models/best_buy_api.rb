class BestBuyApi
  class RequestError < StandardError; end
  class FeedDownError < StandardError; end
  class << self
    BESTBUY_URL = "http://www.bestbuy.ca/en-CA/api"
    DEBUG = false
    
    #Find BestBuy products
    def product_search(id)
      cached_request('product',{:id => id, :Include => "all"})["product"] 
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
    
    #Find all the products in a category
    def listing(id,page=1)
      cached_request('search',{:'categoryPath.id' => id},page)
    end
    
    def category_ids(id)
      ids = []
      page = 1
      totalpages = nil
      while (page == 1 || page <= totalpages)
        res = cached_request('search',{:'categoryPath.id' => id},page)
        totalpages ||= res["totalPages"]
        ids += res["products"].map{|p|p["sku"]}
        page += 1
        sleep 1
      end
      ids
    end
    
    def search(string,page=1)
      cached_request('search',{:name => string},page)
    end

    def cached_request(type, opts, page=1)
      #CachingMemcached.cache_lookup(type + opts.to_s + page.to_s) do
        send_request(type, opts, page)
      #end
    end

    # Generic send request to ECS REST service. You have to specify the :operation parameter.
    def send_request(type,opts,page=1)
      request_url = prepare_url(type,{:page => page},opts)
      log "Request URL: #{request_url}"
      res = Net::HTTP.get_response(URI::parse(request_url))
      unless res.kind_of? Net::HTTPSuccess
        #if res.code == 302
        #  raise BestBuyApi::FeedDownError, "HTTP Response: #{res.code} #{res.message} for #{request_url}"
        #else
          raise BestBuyApi::RequestError, "HTTP Response: #{res.code} #{res.message} for #{request_url}"
        #end
      end
      JSON.parse(res.body)
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
      def prepare_url(type, opts, filters)
        qs = '' #options
        qf = '' #filters
        sf = '' #store filters
        opts.each {|k,v|
          next unless v
          v = v.join(',') if v.is_a? Array
          qs << "&#{k.to_s}=#{URI.encode(v.to_s)}"
        }
        filters.each {|k,v|
          qf = "#{k}=#{v}"
        } unless filters.nil?
        if type == "search"
            "#{BESTBUY_URL}/search/products(#{qf})?#{qs}" #Search for products in certain stores
        else
            return_url = "#{BESTBUY_URL}/#{type}/#{filters[:id]}.aspx"
            return_url << "?Include=#{filters[:Include]}" if filters[:Include]
            return_url
        end
      end
   end
end