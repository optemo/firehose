#--
# Copyright (c) 2009 Jan Ulrich, Optemo Technologies
# Copyright (c) 2006 Herryanto Siatono, Pluit Solutions
#
# Permission is hereby granted, free of charge, to any person obtaining
# a copy of this software and associated documentation files (the
# "Software"), to deal in the Software without restriction, including
# without limitation the rights to use, copy, modify, merge, publish,
# distribute, sublicense, and/or sell copies of the Software, and to
# permit persons to whom the Software is furnished to do so, subject to
# the following conditions:
#
# The above copyright notice and this permission notice shall be
# included in all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
# IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
# CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
# TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
# SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
#++

require 'net/http'
require 'json'
#require 'cgi'

module BestBuy
  class RequestError < StandardError; end
  
  class Remix
    BESTBUY_URL = "http://www.bestbuy.ca/en-CA/api"
    
    attr_writer :debug # debug flag
    attr_writer :options # search options
    
    def initialize
      @debug = false
      @options = {}
    end
    
    #Find BestBuy products
    def product_search(id)
      send_request('product',{:id => id})
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
      end
      ids
    end
    
    def search(string,page=1)
      send_request('search',{:name => string},page)
    end

    # Generic send request to ECS REST service. You have to specify the :operation parameter.
    def send_request(type,opts,page=1)
      @options[:page] = page
      request_url = prepare_url(type,@options,opts)
      log "Request URL: #{request_url}"
      res = Net::HTTP.get_response(URI::parse(request_url))
      unless res.kind_of? Net::HTTPSuccess
        raise BestBuy::RequestError, "HTTP Response: #{res.code} #{res.message}"
      end
      JSON.parse(res.body)
    end
    
  #  protected
      def log(s)
        return unless @debug
        if defined? Rails.logger
          Rails.logger.error(s)
        elsif defined? LOGGER
          LOGGER.error(s)
        else
          puts s
        end
      end
      
   # private 
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