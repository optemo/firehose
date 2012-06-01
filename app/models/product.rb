class Product < ActiveRecord::Base
  require 'sunspot_autocomplete'
  has_many :accessories, :dependent=>:delete_all
  has_many :cat_specs, :dependent=>:delete_all
  has_many :bin_specs, :dependent=>:delete_all
  has_many :cont_specs, :dependent=>:delete_all
  has_many :text_specs, :dependent=>:delete_all
  has_many :product_siblings
  has_many :product_bundles
  attr_writer :product_name
  
  searchable(auto_index: false) do
    text :title do
      cat_specs.find_by_name("title").try(:value)
    end
     
    text :description do
      text_specs.find_by_name("longDescription").try(:value)
    end
    text :sku
    boolean :instock
    string :eq_id_str
    integer :isBundleCont do
      cont_specs.find_by_name(:isBundleCont).try(:value)
    end
    string :product_type do
      cat_specs.find_by_name(:product_type).try(:value)
    end
    
    string :first_ancestors
    string :second_ancestors
    
   (Facet.find_all_by_used_for("filter")+Facet.find_all_by_used_for("sortby")).each do |s|
    if (s.feature_type == "Continuous")
      float s.name.to_sym, trie: true do
        cont_specs.find_by_name(s.name).try(:value)
      end
    elsif (s.feature_type == "Categorical")
      string s.name.to_sym do
        cat_specs.find_by_name(s.name).try(:value)
      end
    elsif (s.feature_type == "Binary")
      string s.name.to_sym do
        bin_specs.find_by_name(s.name).try(:value)
      end
    end
   end
    float :lr_utility, trie: true do
      cont_specs.find_by_name(:lr_utility).try(:value)
    end
    autosuggest :product_name, :using => :instock?                  
  end
  
  def first_ancestors
    if pt = cat_specs.find_by_name(:product_type)
      list = ProductCategory.get_ancestors(pt.value, 3)
      list.join("")+"#{pt.value}" if list
    end
  end
  
  def second_ancestors
    if pt = cat_specs.find_by_name(:product_type)
      list = ProductCategory.get_ancestors(pt.value, 4)
      list.join("")+"#{pt.value}" if list
    end
  end
  
  def eq_id_str
    Equivalence.find_by_product_id(id).try(:eq_id).to_s
  end
  
  def instock?
    if (instock)
      cat_specs.find_by_name("title").try(:value)
    else
      false
    end
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
    
    #Get the candidates from multiple remote_featurenames for one featurename sperately from the other

    holding = ScrapingRule.scrape(product_skus,false,[],true,false)
    candidates_multi = holding[:candidates]
    translations = holding[:translations].uniq
    candidates = ScrapingRule.scrape(product_skus,false,[],false,false)[:candidates]
    candidates += Candidate.multi(candidates_multi,false) #bypass sorting
    
    # Reset the instock flags
    Product.current_type.find_each do |p|
      p.instock = false
      products_to_update[p.sku] = p
    end
    
    all_products_from_retailer = Product.joins(:cat_specs).where(cat_specs: {name: "product_type"}, products: {retailer: Session.retailer})
    product_skus.each do |bb_product|
      # before putting a product into products_to_save, check whether it is in the products table and has a different category
      sku = bb_product.id
      existing_product = products_to_update[sku]
      if existing_product.nil?
        same_sku_products = all_products_from_retailer.where(:sku => sku)
        unless same_sku_products.empty?
          same_sku_different_product_type = same_sku_products.first.cat_specs.where('name = ? AND value NOT IN (?)', "product_type", Session.product_type_leaves)
          unless same_sku_different_product_type.empty?
            #puts sku + ' is an SKU that was found to be under two different product categories'
            products_to_update[bb_product.id] = Product.find(same_sku_different_product_type.first.product_id)
          else
            products_to_save[bb_product.id] = Product.new sku: bb_product.id, instock: false, retailer: Session.retailer
          end
        else
          products_to_save[bb_product.id] = Product.new sku: bb_product.id, instock: false, retailer: Session.retailer
        end
      end
    end
    candidates.each do |candidate|
      spec_class = case candidate.model
        when "Categorical" then CatSpec
        when "Continuous" then ContSpec
        when "Binary" then BinSpec
        when "Text" then TextSpec
        else CatSpec # This should never happen
      end
      raise ValidationError, "Failed to set candidate as delinquent" if (candidate.parsed.nil? && !candidate.delinquent)
      if candidate.delinquent && (p = products_to_update[candidate.sku])
        #This is a feature which was removed
        spec = spec_class.find_by_product_id_and_name(p.id,candidate.name)
        specs_to_delete << spec if spec && !spec.modified
      else
        puts ("Parsed value should not be false, found for " + candidate.sku + ' ' + candidate.name) if (candidate.parsed == "false" && spec_class == BinSpec) # was: raise ValidationError
        if p = products_to_update[candidate.sku]
          #Product is already in the database
          p.instock = true
          # check here whether a spec with product_type exists
          if candidate.name == "product_type"
            spec = spec_class.find_or_initialize_by_product_id_and_name_and_value(p.id, candidate.name, candidate.parsed)
          else
            spec = spec_class.find_or_initialize_by_product_id_and_name(p.id, candidate.name)
          end
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
    Product.import products_to_update.values, :on_duplicate_key_update=>[:instock]
    
    translations.each do |locale, key, value|
      I18n.backend.store_translations(locale, {key => value}, {escape: false})
    end
    
    specs_to_save.each do |s_class, v|
      s_class.import v, :on_duplicate_key_update=>[:product_id, :name, :value] # Bulk insert/update for efficiency
    end
    
    specs_to_delete.each(&:destroy)
    #Save products and associated specs
    products_to_save.values.each(&:save)
    
    ProductBundle.get_relations
    #Get the color relationships loaded
    ProductSibling.get_relations
    Equivalence.fill
    Product.compute_custom_specs(Product.current_type)
    #This assumes Firehose is running with the same memcache as the Discovery Platform
    
    #Reindex sunspot
    Sunspot.index(products_to_save.values)
    Sunspot.index(products_to_update.values)
    Sunspot.commit
    begin
      Rails.cache.clear
    rescue Dalli::NetworkError
      puts "Memcache not available"
    end
  end
  
  def self.compute_custom_specs(bb_prods)
    custom_specs_to_save = Customization.compute_specs(bb_prods.map(&:id))
    custom_specs_to_save.each do |spec_class, spec_values|
      spec_class.import spec_values, :on_duplicate_key_update=>[:product_id, :name, :value]
    end
  end
  
  def name
    name = cat_specs.find_by_name("title").try(:value)
    if name.nil?  
      name = "Unknown Name / Name Not In Database"
    end
    name += "\n"+sku
  end
  
  def img_url
    retailer = cat_specs.find_by_name_and_product_id("product_type",id).try(:value)
    if retailer =~ /^B/
      url = "http://www.bestbuy.ca/multimedia/Products/150x150/"
    elsif retailer =~ /^F/
      url = "http://www.futureshop.ca/multimedia/Products/250x250/"
    else
      raise "No known image link for product: #{sku}"
    end
    url += sku[0..2].to_s+"/"+sku[0..4].to_s+"/"+sku.to_s+".jpg"
  end
  
  def store_sales
    cont_specs.find_by_name("bestseller_store_sales").try(:value)
  end
  
  def total_acc_sales
    Accessory.select(:count).where("`accessories`.`product_id` = #{id} AND `accessories`.`name` = 'accessory_sales_total'").first.count
  end

end

class ValidationError < ArgumentError; end
