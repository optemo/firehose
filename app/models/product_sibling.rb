class ProductSibling < ActiveRecord::Base
  belongs_to :product
  def self.get_relations
    new_siblings = []

    # Find all the 'relations' text specs for the current product type.
    join_query = "INNER JOIN cat_specs ON text_specs.product_id = cat_specs.product_id"
    TextSpec.joins(join_query).where(cat_specs: {name: "product_type",value: Session.product_type_leaves}, text_specs: {name: "relations"}).each do |record|
      relations = JSON.parse(record.value.gsub("=>",":"))
      if relations && !relations.empty?
        product_id = record.product_id
        # Make sure product has a color specified 
        product_color_spec = CatSpec.find_by_product_id_and_name(product_id, "color")
        if not product_color_spec.nil?
          relation_skus = []
          is_bundle = BinSpec.find_by_product_id_and_name(product_id, 'isBundle')
          relations.each do |relation| 
            if relation["type"] == "Variant" 
              sku = relation["sku"]
              # A bundle cannot be a sibling of a non-bundle.
              if (is_bundle and sku.match('B')) or (not is_bundle and not sku.match('B')) 
                relation_skus << sku
              end
            end
          end
           
          # Filter to skus that exist in the database 
          sibling_ids = relation_skus.map{ |sku| Product.find_by_retailer_and_sku(Session.retailer, sku).try(:id) }.compact
          sibling_ids.each do |sibling_id|
            color_spec = CatSpec.find_by_product_id_and_name(sibling_id, "color")
            if not color_spec.nil?
              new_siblings << ProductSibling.new(product_id: product_id, sibling_id: sibling_id, name: "color", value: color_spec.value)
            end
          end
        end
      end  
    end    
    
    # Create hash for efficient lookup
    new_siblings_hash = new_siblings.group_by { |rec| rec.product_id }
    
    # Make sure color relationship is symmetric (R(a,b) => R(b,a))
    new_siblings.clone.each do |rec|
      color_spec = nil # Lazy-initialized color spec for rec.product_id
      sibs_of_sib = new_siblings_hash[rec.sibling_id]
      if sibs_of_sib.nil? or sibs_of_sib.find{ |sib| sib.sibling_id == rec.product_id }.nil?
        if color_spec.nil?
          color_spec = CatSpec.find_by_product_id_and_name(rec.product_id, "color")
        end
        if not color_spec.nil?
          new_siblings << ProductSibling.new(product_id: rec.sibling_id, sibling_id: rec.product_id, name: "color", value: color_spec.value)
        end
      end
    end
    
    # Recreate hash from updated list
    new_siblings_hash = new_siblings.group_by { |rec| rec.product_id }
    
    # Make sure color relationship is transitive (R(a,b) & R(b,c) => R(a,c)) but not reflexive.
    direct_siblings = new_siblings_hash.clone
    while not direct_siblings.empty?
      product_id, recs = direct_siblings.first 
      all_siblings = find_all_siblings(product_id, new_siblings_hash)
      all_siblings.each do |p1|
        p1_sibs = new_siblings_hash[p1].map { |rec| rec.sibling_id }
        all_siblings.each do |p2|
          if p1 != p2 and not p1_sibs.include? p2
            color_spec = CatSpec.find_by_product_id_and_name(p2, "color") 
            if not color_spec.nil?
              new_siblings << ProductSibling.new(product_id: p1, sibling_id: p2, name: "color", value: color_spec.value)
            end
          end
        end
      end
      all_siblings.each { |product_id| direct_siblings.delete(product_id) }
    end

    # Gather all the existing sibling records for the current product type.
    join_query = "INNER JOIN cat_specs ON product_siblings.product_id = cat_specs.product_id"
    old_siblings = ProductSibling.joins(join_query).where(cat_specs: {name: "product_type", value: Session.product_type_leaves})
    
    old_siblings_by_product_id = old_siblings.group_by { |rec| rec.product_id }
    
    current_type_products = Product.current_type.map { |product| product.id }
    
    # Now import the new records which do not already exist in the database
    new_siblings.each do |rec|
      # If the product is not in the current type, then skip it (it should be processed when the update task reaches its type).
      if current_type_products.include? rec.product_id 
        found_match = false
        old_siblings = old_siblings_by_product_id[rec.product_id]
        if not old_siblings.nil? 
          old_rec = old_siblings.find{ |a_rec| a_rec.sibling_id == rec.sibling_id and a_rec.name == rec.name and a_rec.value == rec.value}
          if not old_rec.nil? 
            # Remove it from the array so that the record will *not* be deleted from the database.
            old_siblings.delete(old_rec)
            found_match = true
          end
        end
        if not found_match 
          # No match found so save the new record.
          rec.save
        end
      end
    end
    
    # Delete the old records that are no longer found in the feed
    old_siblings_by_product_id.each do |product_id, recs|
      recs.each { |rec| rec.destroy }
    end
  end
  
  # Recursively find all siblings of the given product.
  #   product_id - The product whose siblings are to be found
  #   siblings_hash - A hash mapping from product ID to ProductSibling records representing direct siblings of that product.
  #   all_siblings - Hash whose keys are all sibling ID's we have found so far (needed to avoid cycles)
  # Returns an array of sibling ID's for the specified product. This array includes the original product ID.
  def self.find_all_siblings(product_id, siblings_hash, all_siblings = {})
    if all_siblings[product_id].nil? # Avoid cycles
      all_siblings[product_id] = true
      siblings = siblings_hash[product_id]
      if not siblings.nil?
        siblings.each do |rec|
          find_all_siblings(rec.sibling_id, siblings_hash, all_siblings)
        end
      end
    end
    all_siblings.keys
  end
  
end
