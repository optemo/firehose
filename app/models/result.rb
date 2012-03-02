class Result < ActiveRecord::Base

  has_many :candidates, :dependent=>:delete_all, :include => [:scraping_rule, :scraping_correction]
  
  def changes
    begin
      oldresult = Result.find(id-2)
    rescue ActiveRecord::RecordNotFound
      return
    end
    
    c = candidates.map(&:product_id).uniq
    old_c = oldresult.candidates.map(&:product_id).uniq
    newproducts = c-old_c
    removedproducts = old_c-c
    "New: <span style='color: green'>[#{newproducts.join(" , ")}]</span> Removed: <span style='color: red'>[#{removedproducts.join(" , ")}]</span>"
  end
  
  def self.upkeep_pre

  end
    
  def self.upkeep_post 
    #Set onsale binary because it's not in the feed
    binspecs = [] # For bulk insert
    featured = BinSpec.where(name: "featured").joins("INNER JOIN cat_specs ON `bin_specs`.product_id = `cat_specs`.product_id").where(cat_specs: {name: "product_type", value: Session.product_type_leaves}).map(&:product)
    (featured+Product.current_type.instock).each do |product|
      saleEnd = CatSpec.find_by_product_id_and_name(product.id,"saleEndDate")
      if saleEnd && saleEnd.value && (Time.parse(saleEnd.value) - 4.hours) > Time.now
        binspec = BinSpec.find_or_initialize_by_product_id_and_name(product.id,"onsale")
        binspec.value = true
        binspecs << binspec
      else
        #Remove sale item if it is there
        binspec = BinSpec.find_by_product_id_and_name(product.id,"onsale")
        binspec.destroy if binspec
      end
      
    end
    # Bulk insert/update with ActiveRecord_import. :on_duplicate_key_update only works on Mysql database
    BinSpec.import binspecs, :on_duplicate_key_update=>[:product_id, :name, :value, :modified] if binspecs.size > 0
  end
end
