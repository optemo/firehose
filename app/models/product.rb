require 'ruby-debug'
class Product < ActiveRecord::Base
  has_many :cat_specs, :dependent=>:delete_all
  has_many :bin_specs, :dependent=>:delete_all
  has_many :cont_specs, :dependent=>:delete_all
  has_many :text_specs, :dependent=>:delete_all
  has_many :search_products, :dependent => :delete_all

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
    Session.product_type.each_char{|c|chars << c.getbyte(0)*chars.size}
    chars.sum*-1
  end
  
  #Currently only does continuous but others should be added
  def self.specs(p_ids = nil)
    st = []
    Session.continuous["filter"].each{|f| st << ContSpec.by_feat(f)}
    #Check for 1 spec per product
    raise ValidationError unless Session.search.products_size == st.first.length
    #Check for no nil values
    raise ValidationError unless st.first.size == st.first.compact.size
    raise ValidationError unless st.first.size > 0
    #Check that every spec has the same number of features
    first_size = st.first.compact.size
    raise ValidationError unless st.inject{|res,el|el.compact.size == first_size}
    
    if p_ids
      Session.categorical["cluster"].each{|f|  st << CatSpec.cachemany(p_ids, f)} 
      Session.binary["cluster"].each{|f|  st << BinSpec.cachemany(p_ids, f)}
    end
    st.transpose
  end
  
  scope :instock, :conditions => {:instock => true}
  scope :valid, lambda {
    {:conditions => (Session.continuous["filter"].map{|f|"id in (select product_id from cont_specs where #{Session.minimum[f] ? "value > " + Session.minimum[f].to_s : "value > 0"}#{" and value < " + Session.maximum[f].to_s if Session.maximum[f]} and name = '#{f}' and product_type = '#{Session.product_type}')"}+\
    Session.binary["filter"].map{|f|"id in (select product_id from bin_specs where value IS NOT NULL and name = '#{f}' and product_type = '#{Session.product_type}')"}+\
    Session.categorical["filter"].map{|f|"id in (select product_id from cat_specs where value IS NOT NULL and name = '#{f}' and product_type = '#{Session.product_type}')"}).join(" and ")}
  }
  scope :current_type, lambda {
    {:conditions => {:product_type => Session.product_type}}
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
    products_to_save = []
    specs_to_save = {}
    #Reset the intock flags
    Product.find_all_by_product_type(result.product_type).each {|p| p.instock = false; products_to_save << p }
    Product.import products_to_save
    products_to_save = []
    rules, multirules, colors = Candidate.organize(result.candidates)
    multirules.each_pair do |feature, candidates|
      #An entry is only in multirules if it has more then one rule
      (candidates||rules[feature].first).each do |candidate|
        spec_class = case candidate.scraping_rule.rule_type
          when "cat" then CatSpec
          when "cont" then ContSpec
          when "bin" then BinSpec
          when "text" then TextSpec
          when "intr" then "intr"
          else CatSpec # This should never happen
                     end
        #Create new product if necessary
        p = Product.find_or_initialize_by_sku_and_product_type(candidate.product_id,Session.product_type)
        if candidate.delinquent && spec_class != "intr"
          #This is a feature which was removed
          spec = spec_class.find_by_product_id_and_name(p.id,feature)
          spec.destroy if spec && !spec.modified
        else
          p.instock = true
          if spec_class == "intr"
            p[feature] = candidate.parsed
            products_to_save << p
          else
            #This is a feature which should be added
            if p.id.nil?
              p.save
            else
              products_to_save << p
            end

            spec = spec_class.find_or_initialize_by_product_id_and_name(p.id,feature)
            spec.product_type = Session.product_type
            spec.value = candidate.parsed
            specs_to_save.keys.include?(spec_class) ? specs_to_save[spec_class] << spec : specs_to_save[spec_class] = [spec]
          end
        end
      end
    end
    Product.import products_to_save
    specs_to_save.each do |s_class, v|
      s_class.import v
    end
    Result.upkeep_pre
    Result.find_bundles
    #Calculate new spec factors
    Product.calculate_factors
    #Get the color relationships loaded
    ProductSiblings.get_relations
    Result.upkeep_post
    #This assumes Firehose is running with the same memcache as the Discovery Platform
    begin
      Rails.cache.clear
    rescue Dalli::NetworkError
      puts "Memcache not available"
    end
  end
  
  def self.calculate_factors
    cont_activerecords = []
    #cat_activerecords =[]
    #bin_activerecords = []
    records = {}
    record_vals = {}
    factors = {}
    all_products = Product.instock.current_type
    prices ||= ContSpec.where(["product_id IN (?) and name = ?", all_products, "price"]).group_by(&:product_id)
    all_products.each do |product|
      utility = []
      (Session.utility["all"]).each do |f|
        if Session.categorical["all"].include?(f)
          records[f] ||= CatSpec.where(["product_id IN (?) and name = ?", all_products, f]).group_by(&:product_id)
        elsif Session.continuous["all"].include?(f)
          records[f] ||= ContSpec.where(["product_id IN (?) and name = ?", all_products, f]).group_by(&:product_id)
        elsif Session.binary["all"].include?(f)
          records[f] ||= BinSpec.where(["product_id IN (?) and name = ?", all_products, f]).group_by(&:product_id)
        else  
          raise ValidationError  
        end
        if records[f][product.id]
          record_vals[f] ||= records[f].values.map{|i|i.first.value}
          factors[f] ||= ContSpec.where(["product_id IN (?) and name = ?", all_products, f+"_factor"]).group_by(&:product_id)
          factorRow = factors[f][product.id] ? factors[f][product.id].first : ContSpec.new(:product_id => product.id, :product_type => Session.product_type, :name => f+"_factor")
          fVal = records[f][product.id].first.value 
          if f=="onsale"
            ori_price = prices[product.id].first.value
            sale_price = records["saleprice"][product.id].first.value
            factorRow.value = Product.calculateFactor_sale(ori_price, sale_price)
          elsif Session.continuous["all"].include?(f)
            factorRow.value = Product.calculateFactor(fVal, f, record_vals[f])
          elsif Session.categorical["all"].include?(f)  
            factorRow.value = Product.calculateFactor_categorical(fVal, f)
          else  
            raise ValidationError  
          end    
          utility << factorRow.value*Product.utility_weights(f) if factorRow.value
          cont_activerecords << factorRow if factorRow.value
        end
      end 
      #Add the static calculated utility
      utilities ||= ContSpec.where(["product_id IN (?) and name = ?", all_products, "utility"]).group_by(&:product_id)
      product_utility = utilities[product.id] ? utilities[product.id].first : ContSpec.new({:product_id => product.id, :product_type => Session.product_type, :name => "utility"})
      product_utility.value = utility.sum
      cont_activerecords << product_utility
    end

    # Do all record saving at the end for efficiency
    ContSpec.import cont_activerecords


    #Clear the search_product cache in the database
    initial_products_id = Product.initial
    SearchProduct.delete_all(["search_id = ?",initial_products_id])

    SearchProduct.import(Product.instock.current_type.map{|product| SearchProduct.new(:product_id => product.id, :search_id => initial_products_id)})

  end
  
  
  private
  
  def self.utility_weights(feature)
    unless @utility_weights
      @utility_weights = {}
      util_sum = Session.utility_weights.map{|k,v| v }.sum.to_f
      Session.utility["all"].each{|f| @utility_weights[f]=Session.utility_weights[f]/util_sum if Session.utility_weights[f]}
    end  
    @utility_weights[feature]
  end
  
  def self.calculateFactor(fVal, f, contspecs)
    # Order the feature values, reversed to give the highest value to duplicates
    return nil if fVal.nil? #Don't process nil vlues
      ordered = contspecs.compact.sort
      ordered = ordered.reverse if Session.prefDirection[f] == 1
      return 0 if Session.prefDirection[f] == 0
      pos = ordered.index(fVal)
      len = ordered.length
      (len - pos)/len.to_f 
  end
  
  def self.calculateFactor_categorical(fVal, f)
     Session.prefered[f].include?(fVal) ? val=  1 : val = 0  
     val
  end   
  
  def self.calculateFactor_sale(fVal1, fVal2) 
     fVal1 > fVal2 ? (fVal1-fVal2)/fVal1 : 0
  end  
end
class ValidationError < ArgumentError; end
