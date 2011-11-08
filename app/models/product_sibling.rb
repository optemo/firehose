require 'ruby-debug'
class ProductSibling < ActiveRecord::Base
  belongs_to :product
  def self.get_relations
    s=Session
    all_products = Product.instock.current_type
    siblings_activerecords = []
    TextSpec.where(["product_id IN (?) and name= ?", all_products, "relations"]).each do |record|
      data = JSON.parse(record.value.gsub("=>",":"))
      if data && !data.empty?
        p_id = record.product_id
        skus = []
        data.each{|sk| skus<<sk["sku"] if sk["type"]=="Variant"} # AdditionalMedia -- has the other image urls. Save these other small image urls instead of colors.
        sibs = [] 
        #Check if the product is in our database
        all_products.map{|p| sibs<<p.id if skus.include?(p["sku"])}
        sibs.each do |sib_id| 
          imgsurl = CatSpec.find_by_product_id_and_name(sib_id,"imgsurl").value
          siblings_activerecords.push ProductSibling.new({:product_id => p_id, :sibling_id =>sib_id, :name=>"imgsurl", :product_type=>s.product_type, :value=> imgsurl}) 
        end
      end  
    end    
    # make sure color relationship is symmetric (R(a,b) => R(b,a))
    siblings_sym_activerecords = []
    siblings_activerecords.each do |p|
      unless siblings_activerecords.inject(false){|res,sib| res || (sib.product_id == p.sibling_id  && sib.sibling_id==p.product_id) || (sib.product_id == p.sibling_id && sib.sibling_id == p.product_id)}
        siblings_activerecords.push ProductSibling.new({:product_id => p.sibling_id, :sibling_id =>p.product_id, :name=>"imgsurl", :product_type=>s.product_type, :value=> CatSpec.find_by_product_id_and_name(p.product_id,"imgsurl").value}) 
      end  
    end
    # make sure color relationship is transitive (R(a,b) & R(b,c)=> R(a,c) but not reflexive)
    siblings_activerecords.each do |s1|
    # list of all siblings for s1 
    siblings = siblings_activerecords.map{|s| s if s.product_id == s1.product_id}.compact
    siblings.each do |s2|
      unless siblings_activerecords.inject(false){|res,sib| res || s1.sibling_id == s2.sibling_id || (sib.product_id == s1.sibling_id  && sib.sibling_id==s2.sibling_id)} 
        siblings_activerecords.push ProductSibling.new({:product_id => s1.sibling_id, :sibling_id => s2.sibling_id, :name=>"imgsurl", :product_type=>s.product_type, :value=> CatSpec.find_by_product_id_and_name(s1.sibling_id,"imgsurl").value})  
      end  
    end
  end
    #delete the old sibling relations
    ProductSibling.delete_all(["product_type = ?", s.product_type])
    #Write the new relations
    ProductSibling.import(siblings_activerecords)
  end
end