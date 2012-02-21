class ProductBundle < ActiveRecord::Base
  belongs_to :product

  def self.get_relations
    copiedspecs = {} # For bulk insert
    product_bundles = []
    TextSpec.where(name: "bundle").joins("INNER JOIN cat_specs ON `text_specs`.product_id = cat_specs.product_id").where(cat_specs: {name: "product_type", value: Session.product_type_leaves}).each do |bundle|
      data = JSON.parse(bundle.value.gsub("=>",":"))
      if data && !data.empty?
        data.map{|d|d["sku"]}.each do |sku|
          p_copy = Product.find_by_sku(sku)
          #Filtering out accessories
          if p_copy && p_copy.product_type == CatSpec.find_by_name_and_product_id("product_type", bundle.product_id).value
            # Get or create new product bundle
            p = ProductBundle.find_or_initialize(bundle_id: bundle.product_id)
            if p.product_id != p_copy.id
              p.product_id = p_copy.id
              product_bundles << p
            end
        
            #Copy over all the products specs
            [ContSpec,BinSpec,CatSpec,TextSpec].each do |s_class|
              s_class.find_all_by_product_id(p_copy.id).each do |spec|
                unless spec.name =="featured" || spec.name =="featured_factor" || spec.name =="next_featured"
                  copiedspec = s_class.find_or_initialize_by_product_id_and_name(p.id,spec.name)
                  if copiedspec.modified || copiedspec.updated_at.nil? || copiedspec.value.blank?
                    copiedspec.value = spec.value
                    copiedspec.modified = true
                    copiedspecs.has_key?(s_class) ? copiedspecs[s_class] << copiedspec : copiedspecs[s_class] = [copiedspec]
                  end
                end  
              end
            end
          end
        end
      else
        #delete old bundle
        ProductBundle.delete_all(product_id: bundle.product_id)
      end
    end
    copiedspecs.each do |s_class, v|
      s_class.import v, :on_duplicate_key_update=>[:product_id, :name, :value, :modified, :updated_at] # Bulk insert/update with ActiveRecord_import, :on_duplicate_key_update only works on Mysql database
    end
    ProductBundle.import product_bundles, :on_duplicate_key_update=>[:bundle_id, :product_id, :created_at, :updated_at]
  end
end
