class Product < ActiveRecord::Base
  has_many :cat_specs
  has_many :bin_specs
  has_many :cont_specs
  has_many :search_products
  
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
  
  def self.create_from_result(id)
    result = Result.find(id)
    Product.find_all_by_product_type(result.product_type).each {|p| p.instock = false; p.save }
    candidate_rules = Candidate.find_all_by_result_id_and_delinquent(id, false).group_by{|c|c.product_id}.each do |r_id, candidate_rules|
      # For each remote id, first figure out whether we already have a product that matches
      unless product = Product.find_by_sku(r_id)
        # Create a new one. The product already exists otherwise.
        product = Product.new({:sku => r_id, :product_type => Session.product_type})
      end
      product.instock = true
      product.save
      candidate_rules.each do |r|
        rule = ScrapingRule.find(r.scraping_rule_id)
        if rule.rule_type == "intr" # Intrinsic properties affect the product directly.
          # No need to create anything, just save the parsed value in the appropriate place
          product[rule.local_featurename] = r.parsed
          product.save
        else
          case rule.rule_type
          when "cat" then spec_class = CatSpec
          when "cont" then spec_class = ContSpec
          when "bin" then spec_class = BinSpec
          else spec_class = CatSpec # This should never happen
      		end
          unless spec = spec_class.find_by_product_id_and_name(product.id, rule.local_featurename)
            spec = spec_class.new({:product_type => Session.product_type, :product_id => product.id, :name => rule.local_featurename})
          end
          spec.value = r.parsed
          spec.save
        end
      end
    end
  end
end
class ValidationError < ArgumentError; end
