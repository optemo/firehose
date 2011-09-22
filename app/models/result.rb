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
  
  def self.cleanupByProductType(product_type, days)
    # Get the date before which the results should be cleanup

    rets = Result.where(:product_type=>product_type).order('created_at desc')
    size = rets.size
    ago = 0
    last_day = rets[0][:created_at].to_date
    (0...size).each do |i|
      
      if rets[i][:created_at].to_date != last_day
        ago += 1
        last_day = rets[i][:created_at].to_date
      end
      break if ago == days - 1
    end
    
    Result.where("product_type=:product_type and created_at < :last_day", {:product_type=>product_type, :last_day=>last_day}).destroy_all
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
    
    #Get BestSeller data from BestBuy Email
    product_orders()
  end
    
  def self.upkeep_post
    #Set onsale binary because it's not in the feed
    binspecs = [] # For bulk insert
    Product.current_type.instock.each do |product|
      price_cont_spec = ContSpec.find_by_product_id_and_name_and_product_type(product.id,"price",Session.product_type)
      saleprice_cont_spec = ContSpec.find_by_product_id_and_name_and_product_type(product.id,"saleprice",Session.product_type)
      if !price_cont_spec.nil? && !saleprice_cont_spec.nil? && price_cont_spec.value > saleprice_cont_spec.value
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
    Product.current_type.instock.each do |p|
      bundle = TextSpec.find_by_product_type_and_product_id_and_name(Session.product_type,p.id,"bundle")
      if bundle
        data = JSON.parse(bundle.value.gsub("=>",":"))
        data.map{|d|d["sku"]}.each do |sku|
          p_copy = Product.find_by_sku(sku)
          if p_copy
            # Get or create new product bundle
            if p_copy.product_type == Session.product_type
              product_bundle = ProductBundle.find_or_initialize_by_bundle_id_and_product_type(p.id, Session.product_type)
              product_bundle.product_id = p_copy.id
              product_bundles << product_bundle
              first_bundle_prod = true
            end

            #Copy over all the products specs
            [ContSpec,BinSpec,CatSpec,TextSpec].each do |s_class|
              s_class.find_all_by_product_type_and_product_id(Session.product_type,p_copy.id).each do |spec|
                copiedspec = s_class.find_by_product_id_and_product_type_and_name(p.id,Session.product_type,spec.name) || s_class.new(:product_id => p.id, :product_type => Session.product_type, :name => spec.name)
                if copiedspec.modified || copiedspec.updated_at.nil?
                  copiedspec.value = spec.value
                  copiedspec.modified = true
                  copiedspecs.keys.include?(s_class) ? copiedspecs[s_class] << copiedspec : copiedspecs[s_class] = [copiedspec]
                end
              end
            end
          end
        end
      end
    end
    copiedspecs.each do |s_class, v|
      s_class.import v, :on_duplicate_key_update=>[:product_id, :name, :value, :modified, :updated_at] # Bulk insert/update with ActiveRecord_import, :on_duplicate_key_update only works on Mysql database
    end
    ProductBundle.delete_all
    ProductBundle.import product_bundles, :on_duplicate_key_update=>[:bundle_id, :product_id, :created_at, :updated_at]
  end

end
