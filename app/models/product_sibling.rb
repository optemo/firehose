class ProductSibling < ActiveRecord::Base
  belongs_to :product
  def self.get_relations
    siblings_activerecords = []
    siblings_unchanged = []
    TextSpec.joins("INNER JOIN `cat_specs` ON `text_specs`.product_id = `cat_specs`.product_id").where(cat_specs: {name: "product_type",value: Session.product_type_leaves}, text_specs: {name: "relations"}).each do |record|
      #Delete old siblings
      ProductSibling.delete_all(product_id: record.product_id)
      ProductSibling.delete_all(sibling_id: record.product_id)
      data = JSON.parse(record.value.gsub("=>",":"))
      if data && !data.empty?
        p_id = record.product_id
        skus = []
        isB = BinSpec.find_by_product_id_and_name(p_id, 'isBundle')
        data.each do |sk|
          skus<<sk["sku"] if sk["type"]=="Variant" && (!isB || (sk["sku"].match('B'))) && (!sk["sku"].match('B') || isB)
        end # AdditionalMedia -- has the other image urls. Save these other small image urls instead of colors.
        #Check if the product is in our database
        sibs = skus.map{|sku|Product.find_by_sku_and_retailer(sku, Session.retailer).try(:id)}.compact
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
    
    # Below code takes sibling relationships and performs transitive closure.
    # Steps: (1) Get product_id <=> matrix index hash 
    # (2) Build up adjacency matrix
    # (3) Run Warshall algorithm on matrix, get transitive matrix
    # (4) Transform back to sibling relationships using hash from (1)
    # (5) Fill out activerecords
    
    # (1) Build up a hash so that accessing matrix row equivalence of a product id is O(n) instead of n^2
    relations = (siblings_activerecords + siblings_unchanged).map{|x| [x.product_id, x.sibling_id]}.sort{|a,b| a[0] <=> b[0]}
    
    keys = relations.map{|x|x[0]}.uniq
    key_hash = {}
    keys.each_with_index {|r,i|key_hash[r] = i}
    dim = keys.length
    # Now we have two-way lookup: key_hash[product_id] => matrix index; or keys[matrix index] => product_id

    # (2) Build adjacency matrix
    adjMatrix=Array.new(keys.length){Array.new(keys.length)}
    relations.each_with_index do |r,i|
      # There is a relation between r[0] and r[1].
      adjMatrix[key_hash[r[0]]][key_hash[r[1]]] = 1
    end
    
    # (3) Run algorithm
    pathMatrix = Warshall.new(adjMatrix).getPathMatrix
    
    siblings_to_create = []
    # (4) Transform back to sibling relationships
    for i in 0...dim do
      for j in 0...dim do
        siblings_to_create << ProductSibling.new({:product_id => keys[i], :sibling_id => keys[j]}) if pathMatrix[i][j]
      end
    end

    # (5) Fill out activerecords
    siblings_to_create = siblings_to_create.select{|s| s.product_id != s.sibling_id}
    siblings_to_create.each do |s| 
      s.value = CatSpec.find_by_product_id_and_name(s.sibling_id,"color").try(:value)
      s.name = "color"
    end

    ProductSibling.import(siblings_to_create)
  end
end
