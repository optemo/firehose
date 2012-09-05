require "sunspot"
require 'sunspot_autocomplete'

class Product < ActiveRecord::Base
  require 'sunspot_autocomplete'

  class InvalidFeedError < StandardError; end

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
  
  # Update the specs for each product under the current product category (as specified by Session.product_type).
  #
  # bb_products - Optional list of BBproduct instances to be updated. If this parameter is nil, the list 
  #                of products for the current product category will be retrieved using the BestBuyApi.
  # is_shallow - When set to true, indicates that we should perform a fast, shallow update. Not all specs
  #              will be updated, just those available in the fast, batched search API.
  def self.feed_update(bb_products = nil, is_shallow = false)
    raise ValidationError unless Session.product_type

    if bb_products and (is_shallow or Session.amazon?)
      raise ValidationError, "Cannot supply bb_products array with is_shallow or Session.amazon? set to true"
    end
    
    existing_products = {}
    Product.current_type.find_each do |p|
      existing_products[p.sku] = p
    end
    
    product_infos = nil
    if is_shallow
      product_infos = get_shallow_product_infos(Session.product_type)
      # If new products have appeared, "upgrade" to a deep update.
      # Reasoning: We do not run most custom rules for shallow updates, because
      # these may depend on specs which are not present in the shallow product info. But if we have
      # a new product, we need to get deep product info and run all custom rules. 
      # Could we run all rules for the new products alone? No -- because some of these rules
      # rely on deep product info being available and up-to-date for *all* products in the category.
      if product_infos.index { |product_info| not existing_products.has_key? product_info.sku }
        puts "Upgrading to deep update for category " + Session.product_type
        is_shallow = false
        short_product_type = ProductCategory.trim_retailer(Session.product_type)
        bb_products = product_infos.map do |product_info| 
          BBproduct.new(id: product_info.english_product_info["sku"], category: short_product_type) 
        end
      end
    end

    # Note that is_shallow may have been set to false inside the 'if' block above.
    if not is_shallow
      if Session.amazon?
        product_infos = get_amazon_product_infos(Session.product_type)
      else
        product_infos = get_product_infos(Session.product_type, bb_products)
      end
    end

    products_to_update = {}
    products_to_save = {}
    specs_to_save = {}
    specs_to_delete = []
    
    # Get the candidates with multiple rules for one local feature name separately
    holding = ScrapingRule.apply_rules(product_infos,false,[],true,false)
    candidates_multi = holding[:candidates]
    translations = holding[:translations].uniq
    holding = ScrapingRule.apply_rules(product_infos,false,[],false,false)
    translations += holding[:translations].uniq
    candidates = holding[:candidates] + Candidate.multi(candidates_multi,false) #bypass sorting
    
    # If the product exists under a different category, we will reuse the existing row in the database.
    # This preserves the invariant that there is only ever one product in the database for a given retailer
    # and SKU.
    product_infos.each do |product_info|
      if not existing_products.has_key?(product_info.sku)
        # Check if the product exists under a different category.
        same_sku_products = Product.where(retailer: Session.retailer, sku: product_info.sku)
        unless same_sku_products.empty?
          existing_products[product_info.sku] = same_sku_products.first
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
      if (candidate.parsed.nil? && !candidate.delinquent)
        raise ValidationError, "Failed to set candidate as delinquent" 
      end
      if candidate.delinquent 
        # The shallow update will not retrieve all product info, so do not delete specs for delinquent rules.
        # Note that this means the shallow update cannot reset binary specs from true back to false (a 
        # delinquent spec represents either a false value or no value in the feed).
        if (p = existing_products[candidate.sku]) and not is_shallow
          #This is a feature which was removed
          spec = spec_class.find_by_product_id_and_name(p.id,candidate.name)
          specs_to_delete << spec if spec && !spec.modified
        end
      else
        if (candidate.parsed == "false" && spec_class == BinSpec) 
          puts ("Parsed value should not be false, found for " + candidate.sku + ' ' + candidate.name) 
        end
        if p = existing_products[candidate.sku]
          #Product is already in the database
          p.instock = true

          # Product should not be deleted.
          products_to_delete.delete(candidate.sku)

          # For shallow update, we only update products whose spec values have changed.
          # For deep update, we add all products to products_to_update, to ensure they are reindexed.
          # This ensures that if an update task crashes between updating the database and reindexing 
          # solr, products updated in the database will be reindexed on the next deep update.
          if not is_shallow 
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
          if is_shallow and not spec.value == candidate.value
            # For shallow update, we only update products whose spec values have changed.
            products_to_update[candidate.sku] = p
            Rails.logger.debug "Shallow update, sku = " + candidate.sku + ", spec name = " + spec.name + ", value changed"
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
      raise InvalidFeedError, "Category " + Session.product_type.to_s + " has " + products_to_delete.size.to_s + 
           " products in the database, but no products in the feed. Existing products will *not* be deleted."
    end

    # For shallow update we should never be creating products (we should have upgraded to a deep update).
    if is_shallow and not products_to_save.empty?
      raise ValidationError, "is_shallow is true but products_to_save is not empty"
    end

    # Bulk insert/update for efficiency
    Product.import products_to_update.values, :on_duplicate_key_update=>[:instock]
    
    # Shallow update does not retrieve French product information.
    if not is_shallow
      translations.each do |locale, key, value|
        I18n.backend.store_translations(locale, {key => value}, {escape: false})
      end
    end
        
    specs_to_save.each do |s_class, v|
      s_class.import v, :on_duplicate_key_update=>[:product_id, :name, :value] # Bulk insert/update for efficiency
    end
    
    specs_to_delete.each(&:destroy)
    #Save products and associated specs
    products_to_save = products_to_save.values.select{|p| !p.cat_specs.select{|cs| cs.name == "product_type"}.empty? }
    products_to_save.map(&:save)
    
    if not products_to_delete.empty?
      products_to_delete.values.each(&:destroy)

      # Commit resulting changes to index.
      Sunspot.commit
    end

    # To save time, we skip bundles and siblings for shallow update. Note that if a new sibling or 
    # bundle appears in the feed, we will automatically upgrade to a deep update for the category.
    if not is_shallow
      ProductBundle.get_relations
      #Get the color relationships loaded
      ProductSibling.get_relations
      Equivalence.fill
    end

    #Customizations
    custom_specs_to_save = Customization.run(products_to_save.map(&:id),products_to_update.values.map(&:id),is_shallow)
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

    # This cleanup step is only required in unusual situations where somehow Solr is
    # out of sync with the database. Skip it for the shallow update.
    if not is_shallow
      products_by_id = Set[*Product.current_type.all.map { |product| product.id }]

      # Remove from Solr products that are present in the index but not in the database.
      Session.product_type_leaves.each do |leaf|
        remove_missing_products_from_solr(leaf, products_by_id)
      end
    end
  end
  
  # Get array of RetailerProductInfos for specified bb_products. If bb_products is nil,
  # the list of products for the specified product type will be retrieved using the 
  # Best Buy API.
  def self.get_product_infos(product_type, bb_products)
    bb_products ||= BestBuyApi.category_ids(product_type)
    retailer_infos = []
    bb_products.each do |bb_product|
      english_product_info = BestBuyApi.get_product_info(bb_product.id, true)
      english_product_info["category_id"] = bb_product.category unless english_product_info.nil?

      french_product_info = BestBuyApi.get_product_info(bb_product.id, false)
      french_product_info["category_id"] = bb_product.category unless french_product_info.nil?

      if english_product_info or french_product_info
        retailer_infos << RetailerProductInfo.new(bb_product.id, english_product_info, french_product_info)
      end
    end

    retailer_infos
  end

  # Get array of RetailerProductInfos for Amazon product type.
  def self.get_amazon_product_infos(product_type)
    amazon_products = AmazonApi.get_all_products(Session.product_type)
    all_product_data = amazon_products['data']

    retailer_infos = []
    amazon_products['ids'].each do |amazon_product|
      product_info = AmazonApi.product_search(amazon_product.id, all_product_data)
      unless product_info.nil?
        product_info["category_id"] = amazon_product.category
        retailer_infos << RetailerProductInfo.new(amazon_product.id, product_info, nil)
      end
    end

    retailer_infos
  end

  # Get array of RetailerProductInfos using the retailer's fast, batched search API.
  # Returned RetailerProductInfo instances do not include French product info.
  def self.get_shallow_product_infos(product_type)
    short_product_type = ProductCategory.trim_retailer(product_type)

    english_product_infos = BestBuyApi.get_shallow_product_infos(product_type, true)

    retailer_infos = []
    english_product_infos.each do |product_info|
      product_info["category_id"] = short_product_type 
      retailer_infos << RetailerProductInfo.new(product_info["sku"], product_info, nil)
    end
    
    retailer_infos
  end

  # Searches Solr for products matching the given product_type, then checks 
  # for each hit whether it is present in the db_products set. Products present
  # in the index but not in the set are removed from the index.
  #
  # product_type - Type of product.
  # db_products - Set of product ids.
  def self.remove_missing_products_from_solr(product_type, db_products) 
    sunspot_hits = []

    curr_page = 1
    total_pages = 1
    while curr_page <= total_pages
      search = Product.search do 
        with :product_type, product_type
        paginate :page => curr_page, :per_page => 200
      end
      total_pages = search.hits.total_pages 
      sunspot_hits += search.hits
      curr_page += 1
    end

    commit_needed = false
    sunspot_hits.each do |hit|
      if not db_products.include? hit.primary_key.to_i
        Sunspot.remove_by_id(Product, hit.primary_key)
        commit_needed = true
      end
    end
    if commit_needed
      Sunspot.commit
    end
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
