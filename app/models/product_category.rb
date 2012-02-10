class ProductCategory < ActiveRecord::Base
  
  def self.get_children(nodes, level=nil)
    nodes = [nodes] unless nodes.class == Array
    search = build_query(nodes, left="l_id > ", right="r_id < ", level)
    CachingMemcached.cache_lookup("ProductCategory#{search.hash}") do
      ProductCategory.where(search).map(&:product_type)
    end
  end
  
  def self.get_ancestors(nodes, level=nil)
    nodes = [nodes] unless nodes.class == Array
    search = build_query(nodes, left="l_id < ", right="r_id > ", level)
    CachingMemcached.cache_lookup("ProductCategory#{search.hash}") do
      ProductCategory.where(search).map(&:product_type)
    end
  end
  
  def self.get_subcategories(node)
    root = ProductCategory.where(:product_type => node).first
    search = "l_id > #{root.l_id} and r_id < #{root.r_id} and retailer = '#{root.retailer}' and level = #{root.level+1}"
    CachingMemcached.cache_lookup("ProductCategory#{search.hash}") do
        ProductCategory.where(search).map(&:product_type)
    end
  end  
  
  def self.get_parent(node)
    root = ProductCategory.where(:product_type => node).first
    search = "l_id < #{root.l_id} and r_id > #{root.r_id} and retailer = '#{root.retailer}' and level = #{root.level-1}"
    CachingMemcached.cache_lookup("ProductCategory#{search.hash}") do
      ProductCategory.where(search).map(&:product_type)
    end
  end
  
  def self.build_query(nodes, left, right, level)
    overall_search = []
    nodes.each do |node|
      root = ProductCategory.where(:product_type => node).first
      search = ""
      search << "(#{left}#{root.l_id} and #{right}#{root.r_id} and retailer = '#{root.retailer}'"
      search << " and level = #{level}" unless level.nil?
      search << ")"
      overall_search << search
    end
    return overall_search.join(" OR ")
  end
  
end
