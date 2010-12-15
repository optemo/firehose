require 'net/http'
require 'json'

class BestBuyApi
  class RequestError < StandardError; end
  class << self
    BESTBUY_URL = "http://www.bestbuy.ca/en-CA/api"
    DEBUG = false
    
    #Find BestBuy products
    def product_search(id)
      send_request('product',{:id => id})["product"]
    end
    
    #Search through the  Categories
    def category_search(id)
      send_request('category',{:id => id})
    end
    
    #Find all the products in a category
    def listing(id,page=1)
      send_request('search',{:'categoryPath.id' => id},page)
    end
    
    def category_ids(id)
      ids = []
      page = 1
      totalpages = 1
      while (page <= totalpages)
        res = send_request('search',{:'categoryPath.id' => id},page)
        totalpages = res["totalPages"]
        ids += res["products"].map{|p|p["sku"]}
        page += 1
        sleep 1
      end
      ids
    end
    
    def search(string,page=1)
      send_request('search',{:name => string},page)
    end

    # Generic send request to ECS REST service. You have to specify the :operation parameter.
    def send_request(type,opts,page=1)
      request_url = prepare_url(type,{:page => page},opts)
      log "Request URL: #{request_url}"
      res = Net::HTTP.get_response(URI::parse(request_url))
      unless res.kind_of? Net::HTTPSuccess
        raise BestBuyApi::RequestError, "HTTP Response: #{res.code} #{res.message} for #{request_url}"
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
            "#{BESTBUY_URL}/#{type}/#{filters[:id]}.aspx"
        end
      end
   end
end