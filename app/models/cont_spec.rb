class ContSpec < ActiveRecord::Base
  belongs_to :product

  # Get specs for a single item, returns a hash of this format: {"price" => 1.75, "width" => ... }
  def self.cache_all(p_id)
    CachingMemcached.cache_lookup("ContSpecs#{p_id}") do
      select("name, value").where(["product_id = ?", p_id]).each_with_object({}){|r, h| h[r.name] = r.value}
    end
  end
  def self.cachemany(p_ids, feat) # Returns numerical (floating point) values only
    CachingMemcached.cache_lookup("ContSpecs#{feat}#{p_ids.join(',').hash}") do
      select("value").where(["product_id IN (?) and name = ?", p_ids, feat]).map(&:value)
    end
  end
  
  # This probably isn't needed anymore, but is a good example of how to do class caching if we want to do it in future.
  def self.featurecache(p_id, feat) 
    @@cs = {} unless defined? @@cs
    p_id = p_id.to_s
    unless @@cs.has_key?(Session.product_type + p_id + feat)
      find_all_by_product_type(Session.product_type).each {|f| @@cs[(Session.product_type + f.product_id.to_s + f.name)] = f}
    end
    @@cs[(Session.product_type + p_id + feat)]
  end
  
  def self.allMinMax(feat)
    CachingMemcached.cache_lookup("#{Session.product_type}MinMax-#{feat}") do
      #all = ContSpec.allspecs(feat)
      all = ContSpec.initial_specs(feat)
      [all.min,all.max]
    end
  end

  def self.allLow(feat)
    CachingMemcached.cache_lookup("#{Session.product_type}Low-#{feat}") do
      ContSpec.initial_specs(feat).sort[Session.search.product_size*0.4]
    end
  end

  def self.allHigh(feat)
    CachingMemcached.cache_lookup("#{Session.product_type}High-#{feat}") do
      ContSpec.initial_specs(feat).sort[Session.search.product_size*0.6]
    end
  end
  
  def == (other)
     return false if other.nil?
     return value == other.value && product_id == other.product_id #&& name == other.name Not included due to partial db instatiations ie .select("product_ids, values")
  end
  
  def self.by_feat(feat)
    SearchProduct.fq2 unless defined? @@by_feat
    @@by_feat[feat]
  end
  
  def self.by_feat=(specs)
    @@by_feat = specs
  end
  
  private
  
  def self.initial_specs(feat)
    joins("INNER JOIN search_products ON cont_specs.product_id = search_products.product_id").where(:cont_specs => {:name => feat}, :search_products => {:search_id => Product.initial}).select("value").map(&:value)
  end
end
