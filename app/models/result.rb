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
end
