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

  
  def create_from_current

    raise ValidationError unless category
    product_skus = BestBuyApi.category_ids(YAML.load(category))
    self.nonuniq = product_skus.count
    product_skus.uniq!{|a|a.id}
    self.total = product_skus.count
    save
    
    candidate_records = ScrapingRule.scrape(product_skus).each{|c|c.result_id = id}
    # Bulk insert
    Candidate.import candidate_records


  end
  
  def self.upkeep_pre
    #Calculate optical zoom for SLR cameras
    if Session.product_type == "camera_bestbuy" #Only do this for cameras
      contspecs = [] # For bulk insert
      Product.current_type.instock.each do |p|
        next if ContSpec.find_by_product_type_and_product_id_and_name(Session.product_type,p.id,"opticalzoom")
        lensrange = CatSpec.find_by_product_type_and_product_id_and_name(Session.product_type,p.id,"lensrange")
        if lensrange
          lensrange = lensrange.value
          ranges = lensrange.split("-")
          v = (ranges[1].to_f/ranges[0].to_f).round(1) #Round to one decimal point
          contspecs << ContSpec.new(:product_type => Session.product_type, :name => "opticalzoom", :product_id => p.id, :value => v)
        end
      end
      # Bulk insert
      ContSpec.import contspecs
    end
  end
    
  def self.upkeep_post
    #Set onsale binary because it's not in the feed
    binspecs = [] # For bulk insert
    featured = BinSpec.find_all_by_product_type_and_name(Session.product_type,"featured").map(&:product)
    (featured+Product.current_type.instock).each do |product|
      saleEnd = CatSpec.find_by_product_id_and_name_and_product_type(product.id,"saleEndDate",Session.product_type)
      if saleEnd && saleEnd.value && (Time.parse(saleEnd.value) - 4.hours) > Time.now
        binspec = BinSpec.find_by_product_id_and_name_and_product_type(product.id,"onsale",Session.product_type) || BinSpec.new(:name => "onsale", :product_type => Session.product_type, :product_id => product.id)
        binspec.value = true
        binspecs << binspec
      else
        #Remove sale item if it is there
        binspec = BinSpec.find_by_product_id_and_name_and_product_type(product.id,"onsale",Session.product_type)
        binspec.destroy if binspec
      end
      
    end
    # Bulk insert/update with ActiveRecord_import. :on_duplicate_key_update only works on Mysql database
    BinSpec.import binspecs, :on_duplicate_key_update=>[:product_id, :name, :value, :modified] if binspecs.size > 0
  end

  def self.find_bundles
    copiedspecs = {} # For bulk insert
    product_bundles = []
    Product.current_type.each do |p|
      bundle = TextSpec.find_by_product_type_and_product_id_and_name(Session.product_type,p.id,"bundle")
      if p.instock && bundle
        data = JSON.parse(bundle.value.gsub("=>",":"))
        data.map{|d|d["sku"]}.each do |sku|
          p_copy = Product.find_by_sku(sku)
          #Filtering out accessories
          if p_copy && p_copy.product_type == Session.product_type
            # Get or create new product bundle
            product_bundle = ProductBundle.find_or_initialize_by_bundle_id_and_product_type(p.id, Session.product_type)
            product_bundle.product_id = p_copy.id
            product_bundles << product_bundle

            #Copy over all the products specs
          
            [ContSpec,BinSpec,CatSpec,TextSpec].each do |s_class|
              s_class.find_all_by_product_type_and_product_id(Session.product_type,p_copy.id).each do |spec|
                unless spec.name =="featured" || spec.name =="featured_factor" || spec.name =="next_featured"
                  copiedspec = s_class.find_by_product_id_and_product_type_and_name(p.id,Session.product_type,spec.name) || s_class.new(:product_id => p.id, :product_type => Session.product_type, :name => spec.name)
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
      end
    end
    #Remove old bundles
    ProductBundle.delete_all(["product_type = ?", Session.product_type])
    copiedspecs.each do |s_class, v|
      s_class.import v, :on_duplicate_key_update=>[:product_id, :name, :value, :modified, :updated_at] # Bulk insert/update with ActiveRecord_import, :on_duplicate_key_update only works on Mysql database
    end
    ProductBundle.import product_bundles, :on_duplicate_key_update=>[:bundle_id, :product_id, :created_at, :updated_at]
  end

end
