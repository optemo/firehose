class BinSpec < ActiveRecord::Base
  belongs_to :product
  
  # Get specs for a single item
  def self.cache_all(p_id)
    CachingMemcached.cache_lookup("BinSpecs#{p_id}") do
      r = select("name, value").where(:product_id => p_id).each_with_object({}){|r, h| h[r.name] = r.value}
    end
  end
  def self.cachemany(p_ids, feat) # Returns numerical (floating point) values only
    CachingMemcached.cache_lookup("BinSpecs#{feat}#{p_ids.join(',').hash}") do
      select("value").where(["product_id IN (?) and name = ?", p_ids, feat]).map(&:value)
    end
  end
end
