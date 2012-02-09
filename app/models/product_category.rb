class ProductCategory < ActiveRecord::Base
  
  
  def self.get_children(node, retailer, level=nil)
    root = ProductCategory.where(:product_type => node).first
    if root
      result = ProductCategory.where("l_id > ? and r_id < ? and retailer = ?", root.l_id, root.r_id, retailer)
      unless level.nil?
        result = result.where(:level => level)
      end
      return result
    end
  end
  
  def self.get_ancestors(node, retailer, level=nil)
    root = ProductCategory.where(:product_type => node).first
    if root
      result = ProductCategory.where("l_id < ? and r_id > ? and retailer = ?", root.l_id, root.r_id, retailer)
      unless level.nil?
        result = result.where(:level => level)
      end
     #result.each do |r|
     #  puts "#{r.product_type} #{r.l_id} #{r.r_id} #{r.level}"
     #end
      return result
    end
  end
  
  def self.get_subcategories(node, retailer)
    root = ProductCategory.where(:product_type => node).first
    if root
      result = ProductCategory.where("l_id > ? and r_id < ? and retailer = ?", root.l_id, root.r_id, retailer).where("level = ?", root.level+1)
     #result.each do |r|
     #  puts "#{r.product_type} #{r.l_id} #{r.r_id} #{r.level}"
     #end
      return result
    end
  end  
  
  def self.get_parent(node, retailer)
    root = ProductCategory.where(:product_type => node).first
    if root
      result = ProductCategory.where("l_id < ? and r_id > ? and retailer = ?", root.l_id, root.r_id, retailer).where("level = ?", root.level-1)
      return result.first
    end
  end
  
  def self.leaves (node)
    node = [node] unless node.class == Array
    node = node[0..0] if Rails.env.test? #Only check first node for testing
    leaves=[]
    retailer = get_retailer(node[0])
    node.each do |n|
      leaves += get_children(n, retailer).where("l_id = (r_id-1)").map{|r| r.product_type}.uniq
    end
    #leaves.each do |l|
     # puts "#{l}"
    #end
    leaves
  end
  def self.get_retailer(node)
     node[0,1]== 'B' ? "bestbuy" : "futureshop"
  end
end
