require "sunspot"
require 'sunspot_autocomplete'

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
  SMALL_CAT_SIZE_NOT_PROTECTED = 3 # Categories of this size or below are not protected from empty feeds
  
  searchable(auto_index: false) do
    text :title do
      text_specs.find_by_name("title").try(:value)
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
    string :product_category do
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
    autosuggest :all_searchable_data, :using => :get_title
    autosuggest :all_searchable_data, :using => :get_category
    #autosuggest :product_instock_title, :using => :instock?
  end
  
  def get_category
    category = cat_specs.find_by_name(:product_type).try(:value)
    if category.nil?
      false
    else
      value = I18n.t "#{category}.name"
    end
    value
  end
  
  def get_title
    text_specs.find_by_name("title").try(:value)
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
      text_specs.find_by_name("title").try(:value)
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
  
  # Returns the list of BBproduct instances for the specified product category.
  def self.get_products(product_type)
    products = []
    begin
      products = BestBuyApi.category_ids(product_type)
    rescue BestBuyApi::TimeoutError
      puts "Timeout calling BestBuyApi.category_ids"
      sleep 30
      retry
    end
    products
  end

  # Update the specs for each product under the current product category (as specified by Session.product_type).
  #
  # product_skus - Optional list of BBproduct instances to be updated. If this parameter is nil, the list 
  #                of products for the current product category will be retrieved using the BestBuyApi.
  def self.feed_update(product_skus = nil)
    raise ValidationError unless Session.product_type
    
    if product_skus.nil?
      product_skus = get_products(Session.product_type)
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
    holding = ScrapingRule.scrape(product_skus,false,[],false,false)
    translations += holding[:translations].uniq
    candidates = holding[:candidates] + Candidate.multi(candidates_multi,false) #bypass sorting
    
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
          # Find all values for this spec. In the past, coding errors and other issues have caused 
          # multiple values for a single local feature name, such as product_type, to appear in the database. 
          specs = spec_class.where(product_id: p.id, name: candidate.name)
          spec = nil
          if specs.empty?
            spec = spec_class.new(product_id: p.id, name: candidate.name)
          else 
            # If there are existing values for this spec, update the first one and delete the rest.
            spec = specs.first
            specs_to_delete.concat(specs[1..-1])
          end
          spec.value = candidate.parsed
          p.set_dirty if spec.changed? #Taint product for indexing
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
    raise ValidationError, "No products are instock" if Product.current_type.length > SMALL_CAT_SIZE_NOT_PROTECTED && (specs_to_save.values.inject(0){|count,el| count+el.count} == 0 && products_to_save.size == 0)

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
    products_to_save = products_to_save.values.select{|p| !p.cat_specs.select{|cs| cs.name == "product_type"}.empty? }
    products_to_save.map(&:save)
    
    ProductBundle.get_relations
    #Get the color relationships loaded
    ProductSibling.get_relations
    Equivalence.fill
    #Customizations
    
    custom_specs_to_save = Customization.run(products_to_save.map(&:id),products_to_update.values.map(&:id))
    custom_specs_to_save.each do |spec_class, spec_values|
      spec_class.import spec_values, :on_duplicate_key_update=>[:product_id, :name, :value]
    end
    
    # Reindex sunspot.
    # We do the index/commit calls in batches of 50 products, as larger batches can result 
    # in timeouts calling Solr (when running the update_parallel rake task).
    products_to_save.each_slice(50) { |slice|
      Sunspot.index(slice)
      Sunspot.commit
    }
    products_to_update.values.each_slice(50) { |slice|
      Sunspot.index(slice)
      Sunspot.commit
    }
    
    #This assumes Firehose is running with the same memcache as the Discovery Platform
    #This assumtion no longer holds
    #begin
    #  Rails.cache.clear
    #rescue Dalli::NetworkError
    #  puts "Memcache not available"
    #end
  end
  
  def name
    name = text_specs.find_by_name("title").try(:value)
    if name.nil?  
      name = "Unknown Name / Name Not In Database"
    end
    name += "\n"+sku
  end
  
  def img_url
    retailer = cat_specs.find_by_name_and_product_id("product_type",id).try(:value)
    url_spec = TextSpec.where(product_id: id, name: 'image_url_s').first
    if url_spec.nil?
      if retailer =~ /^B/
        url = "http://www.bestbuy.ca/multimedia/Products/150x150/"
      elsif retailer =~ /^F/
        url = "http://www.futureshop.ca/multimedia/Products/250x250/"
      else
        raise "No known image link for product: #{sku}"
      end
      url += sku[0..2].to_s+"/"+sku[0..4].to_s+"/"+sku.to_s+".jpg"
    else
      url_spec.value
    end
  end
  
  def store_sales
    cont_specs.find_by_name("bestseller_store_sales").try(:value)
  end
  
  def total_acc_sales
    Accessory.select(:count).where("`accessories`.`product_id` = #{id} AND `accessories`.`name` = 'accessory_sales_total'").first.count
  end
  
  #Allows us to track association changes, but tainting products
  def set_dirty
    @dirty = true
  end
  
  def dirty?
    changed? || !!@dirty
  end

end

class ValidationError < ArgumentError; end
