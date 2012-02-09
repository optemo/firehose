class ProductCategory < ActiveRecord::Base
  
  def self.get_children(node, retailer, level=nil)
    root = ProductCategory.where(:product_type => node, :retailer => retailer).first
    result = ProductCategory.where("l_id > ? and r_id < ? and retailer = ?", root.l_id, root.r_id, retailer)
    unless level.nil?
      result = result.where(:level => level)
    end
    return result
  end
  
  def self.get_ancestors(node, retailer, level=nil)
    root = ProductCategory.where(:product_type => node, :retailer => retailer).first
    result = ProductCategory.where("l_id < ? and r_id > ? and retailer = ?", root.l_id, root.r_id, retailer)
    unless level.nil?
      result = result.where(:level => level)
    end
    return result
  end
  
  def self.get_subcategories(node, retailer)
    root = ProductCategory.where(:product_type => node, :retailer => retailer).first
    result = ProductCategory.where("l_id > ? and r_id < ? and retailer = ?", root.l_id, root.r_id, retailer).where("level = ?", root.level+1)
    return result
  end  
  
  def self.get_parent(node, retailer)
    root = ProductCategory.where(:product_type => node, :retailer => retailer).first
    result = ProductCategory.where("l_id < ? and r_id > ? and retailer = ?", root.l_id, root.r_id, retailer).where("level = ?", root.level-1)
    return result
  end
  
end
