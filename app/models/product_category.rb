class ProductCategory < ActiveRecord::Base
  
  def self.get_children(node, retailer, level=nil)
    root = ProductCategory.where(:product_type => node).first
    result = ProductCategory.where("l_id > ? and r_id < ? and retailer = ?", root.l_id, root.r_id, retailer)
    unless level.nil?
      result = result.where(:level => level)
    end
    return result
  end
  
  def self.get_ancestors(node, retailer, level=nil)
    root = ProductCategory.where(:product_type => node).first
    result = ProductCategory.where("l_id < ? and r_id > ? and retailer = ?", root.l_id, root.r_id, retailer)
    unless level.nil?
      result = result.where(:level => level)
    end
    return result
  end
  
  def self.get_subcategories(node, retailer)
    root = ProductCategory.where(:product_type => node).first
    result = ProductCategory.where("l_id > ? and r_id < ? and retailer = ?", root.l_id, root.r_id, retailer).where("level = ?", root.level+1)
    return result
  end  
  
  def self.get_parent(node, retailer)
    root = ProductCategory.where(:product_type => node).first
    result = ProductCategory.where("l_id < ? and r_id > ? and retailer = ?", root.l_id, root.r_id, retailer).where("level = ?", root.level-1)
    return result
  end
  
  def leaves (node)
    node = [node] unless node.class == Array
    node = node[0..0] if Rails.env.test? #Only check first node for testing
    leaves=[]
    node.each do |n|
      leaves = children(n).where("l_id == (r_id-1)").map{|r| r.product_type}
    end
    leaves.each do |l|
      puts "l"
    end
  end
end
