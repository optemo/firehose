class Product < ActiveRecord::Base
  has_many :cat_specs
  has_many :bin_specs
  has_many :cont_specs
  has_many :search_products
  
  define_index do
    #fields
    indexes "LOWER(title)", :as => :title
    indexes "product_type", :as => :product_type
    set_property :enable_star => true
    set_property :min_prefix_len => 2
    ThinkingSphinx.updates_enabled = false
    ThinkingSphinx.deltas_enabled = false
  end
  
  def self.cached(id)
    CachingMemcached.cache_lookup("Product#{id}"){find(id)}
  end
  
  #Returns an array of results
  def self.manycached(ids)
    res = CachingMemcached.cache_lookup("ManyProducts#{ids.join(',').hash}"){find(ids)}
    if res.class == Array
      res
    else
      [res]
    end
  end
  
  def self.initial
    #Algorithm for calculating id of initial products in product_searches table
    #We probably need a better algorithm to check for collisions
    chars = []
    Session.current.product_type.each_char{|c|chars<<c.getbyte(0)*chars.size}
    chars.sum*-1
  end
  
  #Currently only does continuous but others should be added
  def self.specs(p_ids = nil)
    st = []
    Session.current.continuous["filter"].each{|f| st << ContSpec.by_feat(f)}
    #Check for 1 spec per product
    raise ValidationError unless Session.current.search.products_size == st.first.length
    #Check for no nil values
    raise ValidationError unless st.first.size == st.first.compact.size
    raise ValidationError unless st.first.size > 0
    #Check that every spec has the same number of features
    first_size = st.first.compact.size
    raise ValidationError unless st.inject{|res,el|el.compact.size == first_size}
    
    if p_ids
      Session.current.categorical["cluster"].each{|f|  st<<CatSpec.cachemany(p_ids, f)} 
      Session.current.binary["cluster"].each{|f|  st << BinSpec.cachemany(p_ids, f)}
    end
    st.transpose
  end
  
  scope :instock, :conditions => {:instock => true}
  scope :valid, lambda {
    {:conditions => (Session.current.continuous["filter"].map{|f|"id in (select product_id from cont_specs where #{Session.current.minimum[f] ? "value > " + Session.current.minimum[f].to_s : "value > 0"}#{" and value < " + Session.current.maximum[f].to_s if Session.current.maximum[f]} and name = '#{f}' and product_type = '#{Session.current.product_type}')"}+\
    Session.current.binary["filter"].map{|f|"id in (select product_id from bin_specs where value IS NOT NULL and name = '#{f}' and product_type = '#{Session.current.product_type}')"}+\
    Session.current.categorical["filter"].map{|f|"id in (select product_id from cat_specs where value IS NOT NULL and name = '#{f}' and product_type = '#{Session.current.product_type}')"}).join(" and ")}
  }
    
  def brand
    @brand ||= cat_specs.cache_all(id)["brand"]
  end
  
  def tinyTitle
    @tinyTitle ||= [brand.gsub("Hewlett-Packard", "HP"),model.split(' ')[0]].join(' ')
  end
  
  def descurl
    small_title.tr(' /','_-')
  end

  def mobile_descurl
    "/show/"+[id,brand,model].join('-').tr(' /','_-')
  end
  
  def display(attr, data) # This function is probably superceded by resolutionmaxunit, etc., defined in the appropriate YAML file (e.g. printer_us.yml)
    if data.nil?
      return 'Unknown'
    elsif data == false
      return "None"
    elsif data == true
      return "Yes"
    else
      ending = case attr
        # The following lines are definitely superceded, as noted above
#        when /zoom/
#          ' X'
#        when /[^p][^a][^p][^e][^r]size/
#          ' in.' 
        when /(item|package)(weight)/
          data = data.to_f/100
          ' lbs'
        when /focal/
          ' mm.'
        when /ttp/
          ' seconds'
        else ''
      end
    end
    data.to_s+ending
  end
  
  def self.per_page
    9
  end
end
class ValidationError < ArgumentError; end