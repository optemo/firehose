require 'net/http'
require 'remote_util'
class RuleImageURLs < Customization
  @image_sizes = Hash[ "small" => 100, "medium" => 150, "large" => 250 ]
  @product_type = ['BDepartments','FDepartments', 'ADepartments']
  @needed_features = [{TextSpec => 'thumbnail_url'}]
  @rule_type = 'Text'
  @size_existence = Hash[ "small" => false, "medium" => false, "large" => false ]

  def RuleImageURLs.compute(values, pid)
    unless values[0] =~ /noimage/ || values[0] !~ /.*[Pp]roducts\/.*/ 
      /.*[Pp]roducts\/(?<thumbnail_url>.*)/ =~ values[0]
      retailer = Product.find(pid).retailer
      base_url = ""
      case retailer
      when "B"
        base_url = "http://www.bestbuy.ca/multimedia/Products/"
      when "F"
        base_url = "http://www.futureshop.ca/multimedia/Products/"
      end
    
      uses_default_url = true
      sku = Product.find(pid).sku
      sku_url = ""
      if thumbnail_url =~ /.*\d+\.jpg/
        # Image follows the pattern
        sku_url = sku[0..2].to_s+"/"+sku[0..4].to_s+"/"+sku.to_s+".jpg"
      else
        # Image URL is different
        /.*\d{2,3}x\d{2,3}\/(?<sku_url>.+)/ =~ thumbnail_url
        uses_default_url = false
      end
      # Check existence of each size
      
      @size_existence['small'] = false
      @size_existence['medium'] = false
      @size_existence['large'] = false
      
      if size_exists?("#{base_url}#{@image_sizes["small"]}x#{@image_sizes["small"]}/#{sku_url}")
        @size_existence['small'] = true
      end
      if size_exists?("#{base_url}#{@image_sizes["medium"]}x#{@image_sizes["medium"]}/#{sku_url}")
        @size_existence['medium'] = true
      end
      if size_exists?("#{base_url}#{@image_sizes["large"]}x#{@image_sizes["large"]}/#{sku_url}")
        @size_existence['large'] = true
      end
      res = []
      @image_sizes.each do |name, size|
        /(?<size_tag>\w).*/ =~ name
        if @size_existence[name] && !sku_url.empty?
          name = "image_url_#{size_tag}"
          # Save if URL is different from the default
          unless uses_default_url
            res << makespec(pid, name, "#{base_url}#{size}x#{size}/#{sku_url}")
          end
          #Remove old substitute sizes if they exist
          p = TextSpec.find_or_initialize_by_product_id_and_name(pid, name)
          p.destroy if p
        else
          # Save other image size (ideally larger) in its place
          case size_tag
          when "s"
            if @size_existence['medium']
              res << makespec(pid, "image_url_#{size_tag}", "#{base_url}#{@image_sizes["medium"]}x#{@image_sizes["medium"]}/#{sku_url}")
            elsif @size_existence['large']
              res << makespec(pid, "image_url_#{size_tag}", "#{base_url}#{@image_sizes["large"]}x#{@image_sizes["large"]}/#{sku_url}")
            else
              res << makespec(pid, "image_url_#{size_tag}", "#{base_url}#{thumbnail_url}")
            end
          when "m"
            if @size_existence['large']
              res << makespec(pid, "image_url_#{size_tag}", "#{base_url}#{@image_sizes["large"]}x#{@image_sizes["large"]}/#{sku_url}")
            elsif @size_existence['small']
              res << makespec(pid, "image_url_#{size_tag}", "#{base_url}#{@image_sizes["small"]}x#{@image_sizes["small"]}/#{sku_url}")
            else
              res << makespec(pid, "image_url_#{size_tag}", "#{base_url}#{thumbnail_url}")
            end
          when "l"
            if @size_existence['medium']
              res << makespec(pid, "image_url_#{size_tag}", "#{base_url}#{@image_sizes["medium"]}x#{@image_sizes["medium"]}/#{sku_url}")
            elsif @size_existence['small']
              res << makespec(pid, "image_url_#{size_tag}", "#{base_url}#{@image_sizes["small"]}x#{@image_sizes["small"]}/#{sku_url}")
            else
              res << makespec(pid, "image_url_#{size_tag}", "#{base_url}#{thumbnail_url}")
            end
          end
        end
      end
    else
      unless (Session.retailer == 'A' and values[0] =~ /images-amazon/) # for amazon, if there is a url in the input, do nothing since fine
        BinSpec.find_or_initialize_by_product_id_and_name(pid, "missingImage").update_attributes(value: true)
      end
    end
    res
  end
  
  def RuleImageURLs.size_exists?(url)
    # Check for existence
    url = URI.parse(url.gsub('[', '%5B').gsub(']', '%5D'))
    result = RemoteUtil.do_with_retry(exceptions: [Timeout::Error]) do |except|
      if not except.nil? 
        puts "Timeout retrieving image (" + url.to_s + "), will retry"
      end
      Net::HTTP.start(url.host, url.port).head(url.request_uri).code 
    end
    return result == "200"
  end
  
  def RuleImageURLs.makespec(pid, name, value)
    url_to_add = TextSpec.find_or_initialize_by_product_id_and_name(pid, name)
    url_to_add.value = value
    url_to_add
  end
end
