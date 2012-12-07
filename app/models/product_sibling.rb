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
    
    # This next step ensures partial transitivity of the sibling relationship, but not full transitivity.  Specifically,
    # it ensures R(a,b) & R(a,c) => R(b,c) but not R(a,b) & R(b,c) => R(a,c).  This seems to be sufficient given the
    # current feed from BestBuy (in fact, it is not clear whether we need to ensure symmetry and transitivity at all;
    # it looks like BestBuy may take care of it on their side).
    new_siblings_hash.each do |product_id, recs|
      recs.each do |rec_1|
        recs.each do |rec_2|
          id_1 = rec_1.sibling_id
          id_2 = rec_2.sibling_id
          if id_1 != id_2
            siblings_1 = new_siblings_hash[id_1]
            if siblings_1.nil? or siblings_1.find{ |sib| sib.sibling_id == id_2 }.nil?
              new_siblings << ProductSibling.new(product_id: id_1, sibling_id: id_2, name: "color", value: rec_2.value)
            end
          end
        end
      end
    end

    # Gather all the existing sibling records for the current product type.
    join_query = "INNER JOIN cat_specs ON product_siblings.product_id = cat_specs.product_id"
    old_siblings = ProductSibling.joins(join_query).where(cat_specs: {name: "product_type", value: Session.product_type_leaves})
    
    # Include the records where a product in the current product type is specified as the sibling.
    join_query = "INNER JOIN cat_specs ON product_siblings.sibling_id = cat_specs.product_id"
    old_siblings += ProductSibling.joins(join_query).where(cat_specs: {name: "product_type", value: Session.product_type_leaves})
    old_siblings_by_product_id = old_siblings.group_by { |rec| rec.product_id }
    
    # Now import the new records which do not already exist in the database
    new_siblings.each do |rec| 
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
    
    # Delete the old records that are no longer found in the feed
    old_siblings_by_product_id.each do |product_id, recs|
      recs.each { |rec| rec.destroy }
    end
  end
end
