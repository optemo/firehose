require "sunspot"
require 'sunspot_autocomplete'

class Product < ActiveRecord::Base
  require 'sunspot_autocomplete'
  has_many :accessories, :dependent=>:delete_all
  has_many :cat_specs, :dependent=>:delete_all
  has_many :bin_specs, :dependent=>:delete_all
  has_many :cont_specs, :dependent=>:delete_all
  has_many :text_specs, :dependent=>:delete_all
  has_many :product_siblings, :dependent=>:delete_all
  
  # product_bundles represents the bundles that this product belongs to.
  has_many :product_bundles, :dependent=>:delete_all

  has_one  :equivalence, :dependent=>:delete

  # If this product *is* a bundle, then owned_bundle points to the corresponding ProductBundle.
  # We ensure that the owned_bundle is deleted when this product is destroyed.
  has_one :owned_bundle, :class_name=>"ProductBundle", :foreign_key=>"bundle_id", :dependent=>:delete

  # Ensure rows in product_siblings where sibling_id is this product are deleted when this product
  # is destroyed.
  after_destroy :delete_from_siblings
  
  MIN_PROTECTED_CAT_SIZE = 4 # Categories of this size or greater are protected from empty feeds.
  
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
    text :category_of_product do # needed for keyword search to match category
      category = cat_specs.find_by_name(:product_type).try(:value)
      unless category.nil?  
        I18n.t "#{category}.name"
      end
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
    float :lrutility, trie: true do
      cont_specs.find_by_name(:lrutility).try(:value)
    end
    autosuggest :all_searchable_data do
      if (instock)
        text_specs.find_by_name("title").try(:value)
      end
    end
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
  
  def self.cached(id)
    CachingMemcached.cache_lookup("Product#{id}"){find(id)}
  end

  # Remove rows from product_siblings where this product is the sibling.
  def delete_from_siblings
    ProductSibling.delete_all(sibling_id: id)
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
  # bb_products - Optional list of BBproduct instances to be updated. If this parameter is nil, the list 
  #                of products for the current product category will be retrieved using the BestBuyApi.
  def self.feed_update(bb_products = nil)
    raise ValidationError unless Session.product_type
    
    amazon = true if Session.retailer == "A"
    
    if bb_products.nil?
      unless amazon
        bb_products = get_products(Session.product_type)
      else
        bb_products = AmazonApi.get_all_products(Session.product_type)
      end
    end

    existing_products = {}
    products_to_update = {}
    products_to_save = {}
    specs_to_save = {}
    specs_to_delete = []
    
    #Get the candidates from multiple remote_featurenames for one featurename sperately from the other
    holding = ScrapingRule.scrape(bb_products,false,[],true,false)
    candidates_multi = holding[:candidates]
    translations = holding[:translations].uniq
    holding = ScrapingRule.scrape(bb_products,false,[],false,false)
    translations += holding[:translations].uniq
    candidates = holding[:candidates] + Candidate.multi(candidates_multi,false) #bypass sorting
    
    Product.current_type.find_each do |p|
      existing_products[p.sku] = p
    end
    
    if amazon
      bb_products = bb_products['ids']
    end
    
    # If the product exists under a different category, we will reuse the existing row in the database.
    # This preserves the invariant that there is only ever one product in the database for a given retailer
    # and SKU.
    bb_products.each do |bb_product|
      if not existing_products.has_key?(bb_product.id)
        # Check if the product exists under a different category.
        same_sku_products = Product.where(retailer: Session.retailer, sku: bb_product.id)
        unless same_sku_products.empty?
          existing_products[bb_product.id] = same_sku_products.first
        end
      end
    end

    # Initially, we assume that all existing products will be deleted. Only if at least one scraping rule 
    # matched will a product be removed from this hash.
    products_to_delete = existing_products.clone

    candidates.each do |candidate|
      spec_class = case candidate.model
        when "Categorical" then CatSpec
        when "Continuous" then ContSpec
        when "Binary" then BinSpec
        when "Text" then TextSpec
        else CatSpec # This should never happen
      end
      raise ValidationError, "Failed to set candidate as delinquent" if (candidate.parsed.nil? && !candidate.delinquent)
      if candidate.delinquent 
        if (p = existing_products[candidate.sku])
          #This is a feature which was removed
          spec = spec_class.find_by_product_id_and_name(p.id,candidate.name)
          specs_to_delete << spec if spec && !spec.modified
        end
      else
        puts ("Parsed value should not be false, found for " + candidate.sku + ' ' + candidate.name) if (candidate.parsed == "false" && spec_class == BinSpec) # was: raise ValidationError
        if p = existing_products[candidate.sku]
          #Product is already in the database
          p.instock = true

          # Product should not be deleted ...
          products_to_delete.delete(candidate.sku)

          # ... instead it should be updated.
          if !products_to_update.has_key?(candidate.sku)
            products_to_update[candidate.sku] = p
          end

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
          specs_to_save.has_key?(spec_class) ? specs_to_save[spec_class] << spec : specs_to_save[spec_class] = [spec]
        else 
          #Product is new
          p = products_to_save[candidate.sku] 
          if p.nil? 
            p = Product.new sku: candidate.sku, instock: true, retailer: Session.retailer
            products_to_save[candidate.sku] = p
          end
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

    # We assume that if a category has at least MIN_PROTECTED_CAT_SIZE products in the database, but no products in the
    # feed, this is an error in the feed.
    if products_to_delete.size >= MIN_PROTECTED_CAT_SIZE and products_to_update.size == 0 and products_to_save.size == 0 
      raise ValidationError, "Category " + Session.product_type.to_s + " has " + products_to_delete.size.to_s + 
           " products in the database, but no products in the feed. Existing products will *not* be deleted."
    end

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
    
    products_to_delete.values.each(&:destroy)

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
