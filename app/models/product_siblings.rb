class ProductSiblings < ActiveRecord::Base
  def self.get_relations
    s=Session.current
    ProductSiblings.delete_all(["name = 'color' and product_type = ?", s.product_type])
    all_products = Product.valid.instock
    siblings_activerecords = []
    TextSpec.where(["product_id IN (?) and name= ?", all_products, "relations"]).each do |record|
      data = JSON.parse(record.value.gsub("=>",":"))
      unless !data || data.empty?
        p_id = record.product_id
        skus = []  
        data.each{|sk| skus<<sk["sku"] if sk["type"]=="Variant"}
        sibs = [] 
        #Check if the product is in our database
        all_products.map{|p| sibs<<p.id if skus.include?(p["sku"])}
        color = CatSpec.find_by_product_id_and_name(p_id,"color").value
        sibs.each{|sib_id| siblings_activerecords.push ProductSiblings.new({:product_id => p_id, :sibling_id =>sib_id, :name=>"color", :product_type=>s.product_type, :value=> color})}
      end  
    end    
    
    # make sure color relationship is symmetric (R(a,b) => R(b,a))
    siblings_sym_activerecords = []
    siblings_activerecords.each do |p|
      unless siblings_activerecords.inject(false){|res,sib| res || (sib.product_id == p.sibling_id  && sib.sibling_id==p.product_id)}
        siblings_sym_activerecords.push ProductSiblings.new({:product_id => p.sibling_id, :sibling_id =>p.product_id, :name=>"color", :product_type=>s.product_type, :value=> p.value})
      end  
    end

    #Write products to the database
    ProductSiblings.transaction do 
      siblings_activerecords.each(&:save)
      siblings_sym_activerecords.each(&:save)
    end  
  end
end
