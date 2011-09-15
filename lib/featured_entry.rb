def featured_products(fs, product_type)
  require 'ruby-debug'

  BinSpec.delete_all(["name= ? and product_type = ?", "featured", product_type])
  binspecs = []    
  fs.each do |s|
      product = Product.find_by_sku(s)
      if product
        binspec = BinSpec.new(:product_id => product.id, :name =>"featured", :product_type => product_type)
        binspec.value = 1
        binspecs << binspec
      end  
  end 
  BinSpec.import binspecs, :on_duplicate_key_update=>[:product_id, :name, :value, :modified] if binspecs.size > 0
end  