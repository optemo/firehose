class Product < ActiveRecord::Base
  has_many :cat_specs, :dependent=>:delete_all
  has_many :bin_specs, :dependent=>:delete_all
  has_many :cont_specs, :dependent=>:delete_all
  has_many :text_specs, :dependent=>:delete_all
  has_many :product_siblings
  has_many :product_bundles

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
  
  scope :instock, :conditions => {:instock => true}
  scope :current_type, lambda{ joins(:cat_specs).where(cat_specs: {name: "product_type", value: Session.product_type_leaves})}
  
  def self.feed_update
    raise ValidationError unless Session.product_type
    
    begin
      product_skus = BestBuyApi.category_ids(Session.product_type)
    rescue BestBuyApi::TimeoutError
      puts "Timeout"
      sleep 30
      retry
    end
    #product_skus.uniq!{|a|a.id} #Uniqueness check

    products_to_update = {}
    products_to_save = {}
    specs_to_save = {}
    specs_to_delete = []
    
    #Reset the instock flags
    Product.current_type.find_each do |p|
      p.instock = false
      products_to_update[p.sku] = p
    end

    product_skus.each do |bb_product|
      unless products_to_update[bb_product.id]
        products_to_save[bb_product.id] = Product.new sku: bb_product.id, instock: false
      end
    end
    
    #Get the candidates from multiple remote_featurenames for one featurename sperately from the other
    candidates_multi = ScrapingRule.scrape(product_skus,false,[],true)
    candidates = ScrapingRule.scrape(product_skus,false,[],false)
    candidates += Candidate.multi(candidates_multi,false) #bypass sorting
    
    candidates.each do |candidate|
      spec_class = case candidate.model
        when "Categorical" then CatSpec
        when "Continuous" then ContSpec
        when "Binary" then BinSpec
        when "Text" then TextSpec
        else CatSpec # This should never happen
      end
      #p = products_to_save[candidate.sku] || 
      debugger if (candidate.parsed.nil? && !candidate.delinquent)
      
      if candidate.delinquent && (p = products_to_update[candidate.sku])
        #This is a feature which was removed
        spec = spec_class.find_by_product_id_and_name(p.id,candidate.name)
        specs_to_delete << spec if spec && !spec.modified
      else
        if p = products_to_update[candidate.sku]
          #Product is already in the database
          p.instock = true
          spec = spec_class.find_or_initialize_by_product_id_and_name(p.id,candidate.name)
          spec.value = candidate.parsed
          specs_to_save.has_key?(spec_class) ? specs_to_save[spec_class] << spec : specs_to_save[spec_class] = [spec]
        elsif (p = products_to_save[candidate.sku]) && !candidate.delinquent
          #Product is new
          p.instock = true
          myspecs = case candidate.model
            when "Categorical" then p.cat_specs
            when "Continuous" then p.cont_specs
            when "Binary" then p.bin_specs
            when "Text" then p.text_specs
          end
          myspecs << spec_class.new(name: candidate.name, value: candidate.parsed)
        end
      end
    end
    
    raise ValidationError, "No products are instock" if specs_to_save.values.inject(0){|count,el| count+el.count} == 0 && products_to_save.size == 0
    # Bulk insert/update for efficiency
    Product.import products_to_update.values, :on_duplicate_key_update=> [:sku]
    specs_to_save.each do |s_class, v|
      s_class.import v, :on_duplicate_key_update=>[:product_id, :name] # Bulk insert/update for efficiency
    end
    specs_to_delete.each(&:destroy)
    products_to_save.values.each(&:save) #Save products and associated specs
    
    Result.upkeep_pre
    ProductBundle.get_relations
    #Calculate new spec factors
    Product.calculate_factors
    #Get the color relationships loaded
    ProductSibling.get_relations
    Equivalence.fill
    Result.upkeep_post
    Product.compute_custom_specs(product_skus)
    #This assumes Firehose is running with the same memcache as the Discovery Platform
    begin
      Rails.cache.clear
    rescue Dalli::NetworkError
      puts "Memcache not available"
    end
  end
  
  def self.compute_custom_specs(bb_prods)
    custom_specs_to_save = Customization.compute_specs(bb_prods.map(&:id))
    custom_specs_to_save.each do |spec_class, spec_values|
      spec_class.import spec_values, :on_duplicate_key_update=>[:product_id, :name, :value, :modified]
    end
  end
  
  def self.compute_custom_specs(bb_prods)
    custom_specs_to_save = Customization.compute_specs(bb_prods.map(&:id))
    custom_specs_to_save.each do |spec_class, spec_values|
      spec_class.import spec_values, :on_duplicate_key_update=>[:product_id, :name, :value, :modified]
    end
  end
  
  def self.calculate_factors
    cont_activerecords = [] # For bulk insert/update
    #cat_activerecords =[]
    #bin_activerecords = []
    records = {}
    record_vals = {}
    factors = {}
    all_products = Product.instock.current_type
    prices ||= ContSpec.where(["product_id IN (?) and name = ?", all_products, "price"]).group_by(&:product_id)
    all_products.each do |product|
      utility = []
      Maybe(Session.features["utility"]).each do |f|
        model = case f.feature_type
          when "Categorical" then CatSpec
          when "Continuous" then ContSpec
          when "Binary" then BinSpec
          else raise ValidationError
        end
        records[f.name] ||= model.where(["product_id IN (?) and name = ?", all_products, f.name]).group_by(&:product_id)
        factors[f.name] ||= ContSpec.where(["product_id IN (?) and name = ?", all_products, f.name+"_factor"]).group_by(&:product_id)
        factorRow = factors[f.name][product.id] ? factors[f.name][product.id].first : ContSpec.new(product_id: product.id, name: f.name+"_factor")
        if records[f.name][product.id]
          record_vals[f.name] ||= records[f.name].values.map{|i|i.first.value}
          fVal = records[f.name][product.id].first.value 
          if f.name=="onsale"
            ori_price = prices[product.id].first.value
            sale_price = records["saleprice"][product.id].first.value
            factorRow.value = Product.calculateFactor_sale(ori_price, sale_price)
          elsif f.name == "customerRating"
            factorRow.value = Product.calculateFactor_rating(fVal)
          elsif f.feature_type == "Binary"
            factorRow.value = 1 if fVal
          elsif f.feature_type == "Continuous"
            factorRow.value = Product.calculateFactor(fVal, f, record_vals[f.name])
          elsif f.feature_type == "Categorical"
            unless CategoricalFacetValue.where(["facet_id =? and name=?", f.id, fVal]).empty?
              factorRow.value = 1 
            else
              factorRow.value = 0  
            end  
          else  
            raise ValidationError  
          end    
        else
          factorRow.value = 0    
        end
        utility << factorRow.value*Product.utility_weights(f.name) if factorRow.value
        cont_activerecords << factorRow if factorRow.value
      end 
      #Add the static calculated utility
      utilities ||= ContSpec.where(["product_id IN (?) and name = ?", all_products, "utility"]).group_by(&:product_id)
      product_utility = utilities[product.id] ? utilities[product.id].first : ContSpec.new(product_id: product.id, name: "utility")
      product_utility.value = utility.sum
      cont_activerecords << product_utility
    end

    # Do all record saving at the end for efficiency. :on_duplicate_key_update only works in mysql database
    ContSpec.import cont_activerecords, :on_duplicate_key_update=>[:product_id, :name, :value, :modified]
  end
  
  
  private
  
  def self.utility_weights(f_name)
    unless @utility_weights             #i.e. if @utility_weights is not defined
      @utility_weights = {}
      util_sum = Session.features["utility"].map{|f|f.value.abs}.sum.to_f
      Session.features["utility"].each{|f| @utility_weights[f.name]=f.value.abs/util_sum if f.value}
    end  
    @utility_weights[f_name]
  end
  
  def self.calculateFactor(fVal, f, contspecs)
    # Order the feature values, reversed to give the highest value to duplicates
    return nil if fVal.nil? #Don't process nil vlues
      ordered = contspecs.compact.sort
      ordered = ordered.reverse if f.value < 0 #Negative weight means reversed
      pos = ordered.index(fVal)
      len = ordered.length
      pos/len.to_f 
  end
  
  def self.calculateFactor_sale(fVal1, fVal2) 
     fVal1 > fVal2 ? (fVal1-fVal2)/fVal1 : 0
  end
  
  def self.calculateFactor_rating(fVal)
    fVal >= 4.0 ? 1 : 0
  end
  
end
class ValidationError < ArgumentError; end
