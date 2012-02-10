class ProductSibling < ActiveRecord::Base
  belongs_to :product
  def self.get_relations
    siblings_activerecords = []
    TextSpec.where(name: "relations").joins("INNER JOIN cat_specs ON `text_specs`.product_id = cat_specs.product_id").where(cat_specs: {name: "product_type", value: Session.product_type_leaves}).each do |record|
      data = JSON.parse(record.value.gsub("=>",":"))
      if data && !data.empty?
        p_id = record.product_id
        skus = []
        data.each{|sk| skus<<sk["sku"] if sk["type"]=="Variant"} # AdditionalMedia -- has the other image urls. Save these other small image urls instead of colors.
        #Check if the product is in our database
        sibs = skus.map{|sku|Product.find_by_sku(sku).try(:id)}.compact
        sibs.each do |sib_id|
          color = CatSpec.find_by_product_id_and_name(sib_id,"color").try(:value)
          product_type = CatSpec.find_by_product_id_and_name(sib_id,"product_type").try(:value)
          siblings_activerecords.push ProductSibling.new(product_id: p_id, sibling_id: sib_id, name: "color", product_type: product_type, value: color)
        end
      end  
    end    
    # make sure color relationship is symmetric (R(a,b) => R(b,a))
    siblings_activerecords.each do |p|
       unless siblings_activerecords.inject(false){|res,sib| res || (sib.product_id == p.sibling_id  && sib.sibling_id==p.product_id) }
         siblings_activerecords.push ProductSibling.new(product_id: p.sibling_id, sibling_id: p.product_id, name: "color", product_type: p.product_type, value: CatSpec.find_by_product_id_and_name(p.product_id,"color").value)
      end  
    end
    # make sure color relationship is transitive (R(a,b) & R(b,c)=> R(a,c) but not reflexive)
    siblings_activerecords.each do |s1|
      # list of all siblings for s1 
      siblings = siblings_activerecords.map{|s| s if s.product_id == s1.product_id}.compact
      siblings.each do |s2|
        unless siblings_activerecords.inject(false){|res,sib| res || s1.sibling_id == s2.sibling_id || (sib.product_id == s1.sibling_id  && sib.sibling_id==s2.sibling_id)}   
          siblings_activerecords.push ProductSibling.new(product_id: s1.sibling_id, sibling_id: s2.sibling_id, name: "color", product_type: s2.product_type, value: s2.value)
        end
      end
    end
  
    #delete the old sibling relations
    ProductSibling.delete_all(product_type: Session.product_type_leaves)
    #Write the new relations
    ProductSibling.import(siblings_activerecords)
  end
end
