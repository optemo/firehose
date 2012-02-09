class ProductCategory < ActiveRecord::Base

  def self.children(node, level, retailer)
    root = ProductCategory.where(:product_type => node, :retailer => retailer).first
    children = ProductCategory.where("l_id > ? and r_id < ? and retailer = ?", root.l_id, root.r_id, retailer)
    unless level.nil?
      children = children.where(:level => level)
    end
    return children
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
