require 'net/http'
class RuleImageURLs < Customization
  @image_sizes = Hash[ "small" => 100, "medium" => 150, "large" => 250 ]
  @product_type = ['BDepartments','FDepartments']
  @needed_features = [{TextSpec => 'thumbnail_url'}]
  @rule_type = 'Text'
  
  def RuleImageURLs.compute(values, pid)
    unless values[0] =~ /noimage/
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
      small_exists = false
      medium_exists = false
      large_exists = false
      
      if size_exists?("#{base_url}#{@image_sizes["small"]}x#{@image_sizes["small"]}/#{sku_url}")
        small_exists = true
      end
      if size_exists?("#{base_url}#{@image_sizes["medium"]}x#{@image_sizes["medium"]}/#{sku_url}")
        medium_exists = true
      end
      if size_exists?("#{base_url}#{@image_sizes["large"]}x#{@image_sizes["large"]}/#{sku_url}")
        large_exists = true
      end
      
      res = []
      @image_sizes.each do |name, size|
        /(?<size_tag>\w).*/ =~ name
        if size_exists?("#{base_url}#{size}x#{size}/#{sku_url}")
          # Save if URL is different from the default
          unless uses_default_url
            res << makespec(pid, "image_url_#{size_tag}", "#{base_url}#{size}x#{size}/#{sku_url}")
          end
        else
          # Save other image size (ideally larger) in its place
          case size_tag
          when "s"
            if medium_exists
              res << makespec(pid, "image_url_#{size_tag}", "#{base_url}#{@image_sizes["medium"]}x#{@image_sizes["medium"]}/#{sku_url}")
            elsif large_exists
              res << makespec(pid, "image_url_#{size_tag}", "#{base_url}#{@image_sizes["large"]}x#{@image_sizes["large"]}/#{sku_url}")
            else
              res << makespec(pid, "image_url_#{size_tag}", "#{base_url}#{thumbnail_url}")
            end
          when "m"
            if large_exists
              res << makespec(pid, "image_url_#{size_tag}", "#{base_url}#{@image_sizes["large"]}x#{@image_sizes["large"]}/#{sku_url}")
            elsif small_exists
              res << makespec(pid, "image_url_#{size_tag}", "#{base_url}#{@image_sizes["small"]}x#{@image_sizes["small"]}/#{sku_url}")
            else
              res << makespec(pid, "image_url_#{size_tag}", "#{base_url}#{thumbnail_url}")
            end
          when "l"
            if medium_exists
              res << makespec(pid, "image_url_#{size_tag}", "#{base_url}#{@image_sizes["medium"]}x#{@image_sizes["medium"]}/#{sku_url}")
            elsif small_exists
              res << makespec(pid, "image_url_#{size_tag}", "#{base_url}#{@image_sizes["small"]}x#{@image_sizes["small"]}/#{sku_url}")
            else
              res << makespec(pid, "image_url_#{size_tag}", "#{base_url}#{thumbnail_url}")
            end
          end
        end
      end
    else
      BinSpec.find_or_initialize_by_product_id_and_name(pid, "missingImage").update_attributes(value: true)
    end
    res
  end
  
  def RuleImageURLs.size_exists?(url)
    # Check for existence
    url = URI.parse(url.gsub('[', '%5B').gsub(']', '%5D'))
    return Net::HTTP.start(url.host, url.port).head(url.request_uri).code == "200"
  end
  
  def RuleImageURLs.makespec(pid, name, value)
    url_to_add = TextSpec.find_or_initialize_by_product_id_and_name(pid, name)
    url_to_add.value = value
    url_to_add
  end
end