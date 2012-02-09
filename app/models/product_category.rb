class ProductCategory < ActiveRecord::Base
  
  def self.get_children(nodes, level=nil)
    nodes = [nodes] unless nodes.class == Array
    search = build_query(nodes, left="l_id > ", right="r_id < ", level)
    return ProductCategory.where(search)
  end
  
  def self.get_ancestors(nodes, level=nil)
    nodes = [nodes] unless nodes.class == Array
    search = build_query(nodes, left="l_id < ", right="r_id > ", level)
    return ProductCategory.where(search)
  end
  
  def self.get_subcategories(node)
    root = ProductCategory.where(:product_type => node).first
    return ProductCategory.where("l_id > ? and r_id < ? and retailer = ? and level = ?", root.l_id, root.r_id, root.retailer, root.level+1)
  end  
  
  def self.get_parent(node)
    root = ProductCategory.where(:product_type => node).first
    return ProductCategory.where("l_id < ? and r_id > ? and retailer = ? and level = ?", root.l_id, root.r_id, root.retailer, root.level-1) 
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
