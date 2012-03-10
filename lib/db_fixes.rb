#def set_missing_ids ()
#  #finds largest id number, sets the new id to this+2
#  new_id = DailySpec.select(:id).max.id + 2
#  #only alters rows with id = 0
#  for i in DailySpec.find_all_by_id(0)
#    sku = i.sku
#    date = i.date
#    debugger
#    DailySpec.update_all(:id => new_id, :conditions => {:id => 0, :sku => sku, :date => date}, :limit => 1)
#    new_id += 2
#  end
#end
def set_missing_ids ()
 #finds largest id number, sets the new id to this+2
 new_id = DailySpec.select(:id).max.id + 2
 #only alters rows with id = 0
 
 for i in DailySpec.find_all_by_id(0)
   debugger  
   ds = i
   ds = DailySpec.new(i.attributes)
   ds.id = new_id    #id is not being set! (works if only 1 zero row, not if multiple)
   ds.save
   new_id += 2
 end
end

def populate_retailer_in_products
  # join products with catspec name retailer
  # iterate over all and then set product.retailer to the retailer catspec
  #products_to_save = []
  orphan_products = []
  Product.find_each do |p|
    retailer_spec = CatSpec.find_by_product_id_and_name(p.id, "product_type")
    if retailer_spec.nil?
      orphan_products << p
    else
      p.retailer = retailer_spec.value[0]
      p.save
    end
  end
  #Product.import products_to_save # crashes due to too many
end

#def set_missing_ids ()
# #possible fix at:  http://railsforum.com/viewtopic.php?id=14250  ?
#end