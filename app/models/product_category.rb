class ProductCategory < ActiveRecord::Base
  
  def self.children(node, level, retailer)
    root = ProductCategory.where(:product_type => node, :retailer => retailer).first
    children = ProductCategory.where("l_id > ? and r_id < ? and retailer = ?", root.l_id, root.r_id, retailer)
    unless level.nil?
      children = children.where(:level => level)
    end
    return children
  end
  
end
