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
end
