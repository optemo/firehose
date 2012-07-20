require "sunspot"
require 'sunspot_autocomplete'

class ProductCategory < ActiveRecord::Base
  searchable do
    text :product_category do
      I18n.t "#{product_type}.name"
    end
    autosuggest :all_searchable_data, using: :find_product_category
  end
  
  def find_product_category
    I18n.t "#{product_type}.name"
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
  end
end