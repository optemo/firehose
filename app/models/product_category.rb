require "sunspot"
require 'sunspot_autocomplete'

class ProductCategory < ActiveRecord::Base
  searchable do
    text :product_category do
      I18n.t "#{product_type}.name"
    end
    autosuggest :all_searchable_data do
      I18n.t "#{product_type}.name"
    end
  end
  
  class << self
    def build_query(nodes, left, right, level)
      overall_search = []
      nodes.each do |node|
        root = ProductCategory.where(:product_type => node).first
        if root
          search = "(#{left}#{root.l_id} and #{right}#{root.r_id} and retailer = '#{root.retailer}'"
          search += " and level = #{level}" unless level.nil?
          search << ")"
          overall_search << search
        end
      end
      return overall_search.join(" OR ") unless overall_search.blank?
    end
    
    def multi_node(name,nodes,left,right,level = nil)
      nodes = Array(nodes) #Casts nodes into an array
      CachingMemcached.cache_lookup("PCat#{name}#{nodes.join("-")}#{left}#{right}#{level}") do
        search = build_query(nodes,left,right,level)
        if search
          ProductCategory.where(block_given? ? yield(search) : search).map(&:product_type)
        else
          nil
        end
      end
    end
    
    def single_node(name, node)
      CachingMemcached.cache_lookup("PCat#{name}#{node}") do
        root = ProductCategory.where(:product_type => node).first
        search = yield(root) if root
        if search
          ProductCategory.where(search).map(&:product_type)
        else
          nil
        end
      end
    end
    
    def get_subcategories(node)
      single_node("SubCategories",node) do |root|
        "l_id > #{root.l_id} and r_id < #{root.r_id} and retailer = '#{root.retailer}' and level = #{root.level+1}"
      end
    end  
    
    def get_parent(node)
      single_node("Parent",node) do |root|
        "l_id < #{root.l_id} and r_id > #{root.r_id} and retailer = '#{root.retailer}' and level = #{root.level-1}"
      end
    end
    
    def get_children(nodes, level=nil)
      multi_node("Children",nodes, "l_id > ", "r_id < ", level)
    end
    
    def get_ancestors(nodes, level=nil)
      multi_node("Ancestors",nodes, "l_id < ", "r_id > ", level)
    end
    
    def get_leaves (nodes)
      multi_node("Leaves",nodes, left="l_id >= ", right="r_id <= ") do |query|
        query + "AND l_id=(r_id-1)"
      end
    end

    # Remove the leading retailer character from a category identifier.
    def trim_retailer(product_category)
      product_category_s = product_category.to_s
      if /^[BFA]/ =~ product_category_s
        product_category_s[1..-1] 
      else
        product_category
      end
    end
    
    # Updates the stored product category hierarchy from the best buy api, for a given retailer
    def update_hierarchy(top_node, retailer)
      @categories_to_save = []
      @translations_to_save = []
      @retailer = retailer
      traverse(top_node, 1, 1)
      
      ActiveRecord::Base.transaction do
        # In a transaction, i.e. all of these must complete successfully, otherwise nothing is saved or deleted:
        # delete the old categories for this retailer
        ProductCategory.where(:retailer => retailer).delete_all
        # save the new categories
        ProductCategory.import @categories_to_save
        # save all translations
        @translations_to_save.each do |key, english_name, french_name|
          I18n.backend.store_translations(:en, { key => {"name" => english_name} })
          I18n.backend.store_translations(:fr, { key => {"name" => french_name} })
        end
      end
    end
    
    # used in updating the hierarchy: traverses the subtree of categories starting at root_node, 
    # marks nodes in DFS order, and gets English and French names of the categories
    def traverse(root_node, i, level)
      name = root_node.values.first
      catid = root_node.keys.first
      english_name = root_node.values.first
      
      Session.product_type = @retailer
      
      #print catid + ' '
      
      french_name = BestBuyApi.get_category(catid, false)["name"]
      
      # These categories are left singular in the feed
      # Regex is used fit file encoding (could change it to UTF 8 (according to stackoverflow post) and use the string normally with 'e' accent aigu)
      if english_name == "Digital SLR" && /^Appareil photo reflex (?<need_accent_numerique>num.rique)$/ =~ french_name
        english_name = "Digital SLRs"
        french_name = "Appareils photo reflex #{need_accent_numerique}s"
      end
      
      prefix = @retailer
      
      cat = ProductCategory.new(:product_type => prefix + catid, :feed_id => catid, :retailer => @retailer, 
            :l_id => i, :level => level)
            
      i = i + 1
      children = BestBuyApi.get_subcategories(catid).values.first
      children.each do |child|
        i = traverse(child, i, level+1)
      end
      
      cat.r_id = i
      @categories_to_save << cat
      @translations_to_save << [cat.product_type, english_name, french_name]
      
      i = i + 1
      return i
    end
    
  end
end

