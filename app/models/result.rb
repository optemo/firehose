class Result < ActiveRecord::Base
  has_many :candidates
  has_and_belongs_to_many :scraping_rules
  
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
  
  def remove
    #Remove any associated candidates
    candidates.each(&:destroy)
    #Remove any unneeded scraping rules
    scraping_rules.each do |sr|
      next if sr.active
      next unless Candidate.find_by_scraping_rule_id(sr.id).nil?
      sr.destroy
    end
    #Destroy the results
    destroy
  end
  
  def create_from_current
    self.scraping_rules = ScrapingRule.find_all_by_product_type_and_active(Session.product_type, true)
    raise ValidationError unless category
    product_skus = BestBuyApi.category_ids(YAML.load(category))
    self.nonuniq = product_skus.count
    product_skus.uniq!{|a|a.id}
    self.total = product_skus.count
    save
    
    # Make sure each rule knows which results it is part of
    ScrapingRule.find_all_by_active(true).each {|r| r.results.push(self); r.save}
    candidate_records = ScrapingRule.scrape(product_skus).each{|c|c.result_id = id}
    Candidate.transaction do
      candidate_records.each(&:save)
    end
  end
  
  def self.upkeep_pre
    #Calculate optical zoom for SLR cameras
    Product.current_type.instock.each do |p|
      next if ContSpec.find_by_product_type_and_product_id_and_name(Session.product_type,p.id,"opticalzoom")
      lensrange = CatSpec.find_by_product_type_and_product_id_and_name(Session.product_type,p.id,"lensrange")
      if lensrange
        lensrange = lensrange.value
        ranges = lensrange.split("-")
        v = (ranges[1].to_f/ranges[0].to_f).round(1) #Round to one decimal point
        ContSpec.create(:product_type => Session.product_type, :name => "opticalzoom", :product_id => p.id, :value => v)
      end
    end
  end
    
  def self.upkeep_post
    #Set onsale binary because it's not in the feed
    binspecs = []
    Product.current_type.instock.each do |product|
      if ContSpec.find_by_product_id_and_name_and_product_type(product.id,"price",Session.product_type).value > ContSpec.find_by_product_id_and_name_and_product_type(product.id,"saleprice",Session.product_type).value
        binspec = BinSpec.find_by_product_id_and_name_and_product_type(product.id,"onsale",Session.product_type) || BinSpec.new(:name => "onsale", :product_type => Session.product_type, :product_id => product.id)
        binspec.value = true
        binspecs << binspec
      else
        #Remove sale item if it is there
        binspec = BinSpec.find_by_product_id_and_name_and_product_type(product.id,"onsale",Session.product_type)
        binspec.destroy if binspec
      end
      
    end
    BinSpec.transaction do
      binspecs.each(&:save)
    end
    
  end
  
  def self.find_bundles
    Product.current_type.instock.each do |p|
      bundle = TextSpec.find_by_product_type_and_product_id_and_name(Session.product_type,p.id,"bundle")
      if bundle
        data = JSON.parse(bundle.value.gsub("=>",":"))
        data.map{|d|d["sku"]}.each do |sku|
          p_copy = Product.find_by_sku(sku)
          if p_copy
            #Copy over all the products specs
            [ContSpec,BinSpec,CatSpec,TextSpec].each do |s_class|
              s_class.find_all_by_product_type_and_product_id(Session.product_type,p_copy.id).each do |spec|
                copiedspec = s_class.find_by_product_id_and_product_type_and_name(p.id,Session.product_type,spec.name) || s_class.new(:product_id => p.id, :product_type => Session.product_type, :name => spec.name)
                if copiedspec.modified || copiedspec.updated_at.nil?
                  copiedspec.value = spec.value
                  copiedspec.modified = true
                  copiedspec.save
                end
              end
            end
          end
        end
      end
    end
  end
end
