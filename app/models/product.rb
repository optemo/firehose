class Product < ActiveRecord::Base
  has_many :cat_specs, :dependent=>:delete_all
  has_many :bin_specs, :dependent=>:delete_all
  has_many :cont_specs, :dependent=>:delete_all
  has_many :text_specs, :dependent=>:delete_all
  has_many :search_products, :dependent => :delete_all
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
  scope :current_type, lambda {
    {:conditions => {:product_type => Session.product_type}}
  }
  
  def self.feed_update
    raise ValidationError unless Session.category_id
    product_skus = BestBuyApi.category_ids(Session.category_id)
    #product_skus.uniq!{|a|a.id} #Uniqueness check
    #Get the candidates from multiple remote_featurenames for one featurename sperately from the other
    candidates_multi = ScrapingRule.scrape(product_skus,false,[],true)
    candidates = ScrapingRule.scrape(product_skus,false,[],false)
    #Reset the instock flags
    Product.update_all(['instock=false'], ['product_type=?', Session.product_type])
    
    products_to_save = {}
    product_skus.each do |bb_product|
      products_to_save[bb_product.id] = Product.find_or_initialize_by_sku_and_product_type(bb_product.id, Session.product_type)
    end
    specs_to_save = {}
    
    candidates += Candidate.multi(candidates_multi,false) #bypass sorting
    candidates.each do |candidate|
      spec_class = case candidate.model
        when "cat" then CatSpec
        when "cont" then ContSpec
        when "bin" then BinSpec
        when "text" then TextSpec
        else CatSpec # This should never happen
      end
      p = products_to_save[candidate.sku]
    
      if p.new_record?
        p.save
      end
      
      if candidate.delinquent
        #This is a feature which was removed
        spec = spec_class.find_by_product_id_and_name(p.id,candidate.name)
        spec.destroy if spec && !spec.modified
      else
        p.instock = true
        spec = spec_class.find_or_initialize_by_product_id_and_name(p.id,candidate.name)
        spec.product_type = Session.product_type
        spec.value = candidate.parsed
        specs_to_save.has_key?(spec_class) ? specs_to_save[spec_class] << spec : specs_to_save[spec_class] = [spec]
      end
    end
    puts "Done Calculations #{Session.product_type} - #{Time.now}"
    # Bulk insert/update for efficiency
    Product.import products_to_save.values, :on_duplicate_key_update=> [:sku, :product_type, :title, :model, :mpn, :instock]
    specs_to_save.each do |s_class, v|
      s_class.import v, :on_duplicate_key_update=>[:product_id, :name, :value, :modified] # Bulk insert/update for efficiency
    end
    puts "Done DB insert #{Session.product_type} - #{Time.now}"
    Result.upkeep_pre
    puts "Done Upkeep Pre #{Session.product_type} - #{Time.now}"
    Result.find_bundles
    puts "Done Bundles #{Session.product_type} - #{Time.now}"
    #Calculate new spec factors
    Product.calculate_factors
    puts "Done Calculate Factors #{Session.product_type} - #{Time.now}"
    #Get the color relationships loaded
    ProductSibling.get_relations
    puts "Done Siblings #{Session.product_type} - #{Time.now}"
    Equivalence.fill
    puts "Done Equivalence #{Session.product_type} - #{Time.now}"
    Result.upkeep_post
    puts "Done Upkeep Post #{Session.product_type} - #{Time.now}"
    #This assumes Firehose is running with the same memcache as the Discovery Platform
    begin
      Rails.cache.clear
    rescue Dalli::NetworkError
      puts "Memcache not available"
    end
    
  end
  
  def self.create_from_result(id)
    result = Result.find(id)
    products_to_save = {}
    specs_to_save = {}
    #Reset the intock flags
    Product.update_all(['instock=false'], ['product_type=?', result.product_type])
    
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
        if products_to_save.keys.include?(candidate.product_id)
          p = products_to_save[candidate.product_id]
        else
          p = Product.find_or_initialize_by_sku_and_product_type(candidate.product_id,Session.product_type)
        end

        if p.new_record?
          p.save
        end
        if candidate.delinquent && spec_class != "intr"
          #This is a feature which was removed
          spec = spec_class.find_by_product_id_and_name(p.id,feature)
          spec.destroy if spec && !spec.modified
        else
          p.instock = true
          if spec_class == "intr"
            p[feature] = candidate.parsed
            products_to_save[candidate.product_id] = p 
          else
            spec = spec_class.find_or_initialize_by_product_id_and_name(p.id,feature)
            
            spec.product_type = Session.product_type
            spec.value = candidate.parsed
            specs_to_save.keys.include?(spec_class) ? specs_to_save[spec_class] << spec : specs_to_save[spec_class] = [spec]
            if feature=='mpn' || feature=='title' || feature=='model'
              p[feature] = spec.value
            end
            products_to_save[candidate.product_id] = p

          end
        end
      end
    end
    # Bulk insert/update for efficiency
    Product.import products_to_save.values, :on_duplicate_key_update=> [:sku, :product_type, :title, :model, :mpn, :instock]
    specs_to_save.each do |s_class, v|
      s_class.import v, :on_duplicate_key_update=>[:product_id, :name, :value, :modified] # Bulk insert/update for efficiency
    end
    Result.upkeep_pre
    Result.find_bundles
    #Calculate new spec factors
    Product.calculate_factors
    #Get the color relationships loaded
    ProductSibling.get_relations
    Equivalence.fill
    Result.upkeep_post
    #This assumes Firehose is running with the same memcache as the Discovery Platform
    begin
      Rails.cache.clear
    rescue Dalli::NetworkError
      puts "Memcache not available"
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
        factorRow = factors[f.name][product.id] ? factors[f.name][product.id].first : ContSpec.new(:product_id => product.id, :product_type => Session.product_type, :name => f.name+"_factor")
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
      product_utility = utilities[product.id] ? utilities[product.id].first : ContSpec.new({:product_id => product.id, :product_type => Session.product_type, :name => "utility"})
      product_utility.value = utility.sum
      cont_activerecords << product_utility
    end

    # Do all record saving at the end for efficiency. :on_duplicate_key_update only works in mysql database
    ContSpec.import cont_activerecords, :on_duplicate_key_update=>[:product_id, :name, :value, :modified]

    #Clear the search_product cache in the database
    SearchProduct.transaction do
      SearchProduct.delete_all(["search_id = ?",Session.product_type_id])
      # Bulk insert for efficiency. 
      SearchProduct.import(Product.instock.current_type.map{|product| SearchProduct.new(:product_id => product.id, :search_id => Session.product_type_id)})
    end
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
      (len - pos)/len.to_f 
  end
  
  def self.calculateFactor_sale(fVal1, fVal2) 
     fVal1 > fVal2 ? (fVal1-fVal2)/fVal1 : 0
  end
  
  def self.calculateFactor_rating(fVal)
    fVal >= 4.0 ? 1 : 0
  end
  
end
class ValidationError < ArgumentError; end
