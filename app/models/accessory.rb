class Accessory < ActiveRecord::Base
  belongs_to :product
  
  def img_url
    retailer = CatSpec.find_by_name_and_product_id("product_type",value).try(:value)
    if retailer =~ /^B/
      url = "http://www.bestbuy.ca/multimedia/Products/150x150/"
    elsif retailer =~ /^F/
      url = "http://www.futureshop.ca/multimedia/Products/250x250/"
    else
      raise "No known image link for product: #{sku}"
    end
    
    url += sku[0..2].to_s+"/"+sku[0..4].to_s+"/"+sku.to_s+".jpg"
  end
  
  def sku
    sku = Product.find_by_id(value).try(:sku)
  end
  
end
