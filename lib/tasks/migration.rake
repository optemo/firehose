#Here is where scripts required for a migration task go
desc "Assigns the proper leaf nodes given the current tree nodes"
task :assign_leafs => :environment do
  Product.all.each do |p|
    #Old category id
    product_type = CatSpec.find_by_name_and_product_id("product_type",p.id)
    next if product_type.value == "B00000"
    treenodes = [product_type.value[1..-1]]
    #Find the leaf nodes
    leafnodes = []
    treenodes.each do |tnode|
      children = BestBuyApi.get_subcategories(tnode).values.first.map do |hash|
        hash.keys.first
      end
      if children.empty?
        leafnodes << tnode
      else
        children.each do |c|
          treenodes << c
        end
      end
    end
    
    #Search for this product in the leaf nodes
    found = BestBuyApi.category_ids(leafnodes).select{|bbp|bbp.id == p.sku}.first
    if found.nil?
      puts "#{leafnodes}"
      exit
    end
    #Update product_type to leaf node
    product_type.update_attribute(:value, product_type.value[0]+found.category)
  end
end
