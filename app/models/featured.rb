class Featured < ActiveRecord::Base
  def name
    cat_specs.find_by_name("title").try(:value)+"\n"+sku)
  end
  
  def self.get_sku(product_id)
    Product.find_by_id(product_id).try(:sku)
  end
  
end