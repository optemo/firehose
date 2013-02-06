class Accessory < ActiveRecord::Base
  belongs_to :product
  
  def img_url
    retailer = CatSpec.find_by_name_and_product_id("product_type",value).try(:value)
    if retailer =~ /^B/
      url = "http://firehose-demo/assets/product_images/bb_images/"
    elsif retailer =~ /^F/
      url = "http://firehose-demo/assets/product_images/futureshop_images/"
    else
      raise "No known image link for product: #{sku}"
    end
    
    url += sku + ".jpg"
  end
  
  def sku
    sku = Product.find_by_id(value).try(:sku)
  end
  
end
