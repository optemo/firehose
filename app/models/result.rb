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
  
  def self.upkeep
    #Set onsale binary because it's not in the feed
    binspecs = []
    Product.valid.instock.each do |product|
      binspec = BinSpec.find_by_product_id_and_name_and_product_type(product.id,"onsale",Session.product_type) || BinSpec.new(:name => "onsale", :product_type => Session.product_type, :product_id => product.id)
      if ContSpec.find_by_product_id_and_name_and_product_type(product.id,"price",Session.product_type).value > ContSpec.find_by_product_id_and_name_and_product_type(product.id,"saleprice",Session.product_type).value
        binspec.value = true
      else
        binspec.value = false
      end
      binspecs << binspec
    end
    BinSpec.transaction do
      binspecs.each(&:save)
    end
  end
end
