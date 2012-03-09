class ProductSibling < ActiveRecord::Base
  belongs_to :product
  def self.get_relations
    siblings_activerecords = []
    siblings_unchanged = []
    TextSpec.where(name: "relations").joins("INNER JOIN cat_specs ON `text_specs`.product_id = cat_specs.product_id").where(cat_specs: {name: "product_type", value: Session.product_type_leaves}).each do |record|
      data = JSON.parse(record.value.gsub("=>",":"))
      if data && !data.empty?
        p_id = record.product_id
        skus = []
        data.each{|sk| skus<<sk["sku"] if sk["type"]=="Variant"} # AdditionalMedia -- has the other image urls. Save these other small image urls instead of colors.
        #Check if the product is in our database
        sibs = skus.map{|sku|Product.find_by_sku(sku).try(:id)}.compact
        sibs.each do |sib_id|
          ps = ProductSibling.find_or_initialize_by_product_id(p_id)
          if ps.sibling_id != sib_id
            ps.sibling_id = sib_id
            ps.name = "color"
            ps.value = CatSpec.find_by_product_id_and_name(sib_id,"color").try(:value)
            siblings_activerecords << ps
          else
            siblings_unchanged << ps
          end
        end
      else
        #Delete old siblings
        ProductSibling.delete_all(product_id: record.product_id)
      end  
    end    
    # make sure color relationship is symmetric (R(a,b) => R(b,a))
    (siblings_unchanged + siblings_activerecords).each do |p|
       unless (siblings_unchanged + siblings_activerecords).inject(false){|res,sib| res || (sib.product_id == p.sibling_id  && sib.sibling_id==p.product_id) }
         ps = ProductSibling.find_or_initialize_by_product_id(p.sibling_id)
         if ps.sibling_id != p.product_id
           ps.sibling_id = p.product_id
           ps.name = "color"
           ps.value = CatSpec.find_by_product_id_and_name(p.product_id,"color").try(:value)
           siblings_activerecords << ps
         else
           siblings_unchanged << ps
         end
      end  
    end
    # make sure color relationship is transitive (R(a,b) & R(b,c)=> R(a,c) but not reflexive)
    (siblings_unchanged + siblings_activerecords).each do |s1|
      # list of all siblings for s1 
      siblings = (siblings_unchanged + siblings_activerecords).map{|s| s if s.product_id == s1.product_id}.compact
      siblings.each do |s2|
        unless (siblings_unchanged + siblings_activerecords).inject(false){|res,sib| res || s1.sibling_id == s2.sibling_id || (sib.product_id == s1.sibling_id  && sib.sibling_id==s2.sibling_id)}
          ps = ProductSibling.find_or_initialize_by_product_id(s1.sibling_id)
          if ps.sibling_id != s2.sibling_id
            ps.sibling_id = s2.sibling_id
            ps.name = "color"
            ps.value = s2.value
            siblings_activerecords << ps
          else
            siblings_unchanged << ps
          end
        end
      end
    end
    #Write the new relations
    ProductSibling.import(siblings_activerecords)
  end
end
