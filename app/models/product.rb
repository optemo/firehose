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
    #Reset the intock flags
    Product.find_all_by_product_type(result.product_type).each {|p| p.instock = false; p.save }
    rules, multirules, colors = Candidate.organize(result.candidates)
    multirules.each_pair do |feature, candidates|
      #An entry is only in multirules if it has more then one rule
      (candidates||rules[feature].values.first.first).each do |candidate|
        next if candidate.delinquent
        #Create new product if necessary
        p = Product.find_or_initialize_by_sku_and_product_type(candidate.product_id,Session.current.product_type)
        p.instock = true
        if candidate.scraping_rule.rule_type == "intr"
          p[feature] = candidate.parsed
          p.save
        else
          case candidate.scraping_rule.rule_type
            when "cat" then spec_class = CatSpec
            when "cont" then spec_class = ContSpec
            when "bin" then spec_class = BinSpec
            when "text" then spec_class = TextSpec
            else spec_class = CatSpec # This should never happen
      		end
      		p.save
      		#Save the spec
      		spec = spec_class.find_or_initialize_by_product_id_and_name(p.id,feature)
      		spec.product_type = Session.current.product_type
      		spec.value = candidate.parsed
      		spec.save
    		end
      end
    end
    #Calculate new spec factors
    Product.calculate_factors
    #Get the color relationships loaded
    ProductSiblings.get_relations
  end
  
  def self.calculate_factors
    s = Session.current
    cont_activerecords = []
    #cat_activerecords =[]
    #bin_activerecords = []
    records = {}
    record_vals = {}
    factors = {}
    all_products = Product.valid.instock
    all_products.each do |product|
      utility = []
      s.continuous["filter"].each do |f|
        records[f] ||= ContSpec.where(["product_id IN (?) and name = ?", all_products, f]).group_by(&:product_id)
        record_vals[f] ||= records[f].values.map{|i|i.first.value}
        factors[f] ||= ContSpec.where(["product_id IN (?) and name = ?", all_products, f+"_factor"]).group_by(&:product_id)
        factorRow = factors[f][product.id].first || ContSpec.new(:product_id => product.id, :product_type => s.product_type, :name => f+"_factor")
        fVal = records[f][product.id].first
        debugger unless fVal && fVal.value # The alternative here is to crash. This should never happen if Product.valid.instock is doing its job.
        factorRow.value = Product.calculateFactor(fVal.value, f, record_vals[f])
        utility << factorRow.value
        cont_activerecords << factorRow
      end
      #Add the static calculated utility
      utilities ||= ContSpec.where(["product_id IN (?) and name = ?", all_products, "utility"]).group_by(&:product_id)
      product_utility = utilities[product.id].first || ContSpec.new({:product_id => product.id, :product_type => s.product_type, :name => "utility"})
      product_utility.value = utility.sum
      cont_activerecords << product_utility
    end

    # Do all record saving at the end for efficiency
    ContSpec.transaction do
      cont_activerecords.each(&:save)
    end

    #Clear the search_product cache in the database
    initial_products_id = Product.initial
    SearchProduct.delete_all(["search_id = ?",initial_products_id])
    SearchProduct.transaction do
      Product.valid.instock.map{|product| SearchProduct.new(:product_id => product.id, :search_id => initial_products_id)}.each(&:save)
    end
  end
  
  private
  
  def self.calculateFactor(fVal, f, contspecs)
    # Order the feature values, reversed to give the highest value to duplicates
    ordered = contspecs.sort
    ordered = ordered.reverse if Session.current.prefDirection[f] == 1
    return 0 if Session.current.prefDirection[f] == 0
    pos = ordered.index(fVal)
    len = ordered.length
    (len - pos)/len.to_f
  end
end
class ValidationError < ArgumentError; end
