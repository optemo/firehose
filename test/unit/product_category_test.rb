require 'test_helper'

class ProductCategoryTest < ActiveSupport::TestCase
 
  setup do
    create(:product_category, product_type: "B30317a", l_id: 53, r_id: 58, level: 1)
    create(:product_category, product_type: "B28597", l_id: 54, r_id: 55, level: 2)
    create(:product_category, product_type: "B29172", l_id: 56, r_id: 57, level: 2)
    create(:product_category, product_type: "B29339", l_id: 59, r_id: 68, level: 1)
    create(:product_category, product_type: "B29340", l_id: 60, r_id: 65, level: 2)
    create(:product_category, product_type: "B29341", l_id: 61, r_id: 62, level: 3)
    create(:product_category, product_type: "B29342", l_id: 63, r_id: 64, level: 3)
    create(:product_category, product_type: "B29343", l_id: 66, r_id: 67, level: 2)
  end 
 
 
  test "get_children and leaves methods" do 
        
    #test a node without any children
    assert_equal ["B28597"], ProductCategory.get_leaves("B28597")
    #test a single node with one level of children

    assert_equal 2, ProductCategory.get_leaves("B30317a").uniq.count
    #test an array of nodes with more than one level children

    assert_equal 6,  ProductCategory.get_leaves(["B30317a","B29339"]).uniq.count
  end
  
  test "get_ancestors method" do  
    #test a node with out any ancestors
    assert_equal [], ProductCategory.get_ancestors("B30317a")
    #test a node that doesn't exist
    assert_nil ProductCategory.get_ancestors("BDepart")
    #test an array of nodes for  their ancestors at a specific level
    assert_equal ["B29339"], ProductCategory.get_ancestors(["B29341","B29342"], 1).uniq
    #test a node for all of its ancestors
    assert_equal 2, ProductCategory.get_ancestors("B29341").uniq.count
  end
  
  test "get_parent method" do  
    #test a node with for its parent
    assert_equal "B29340", ProductCategory.get_parent("B29341").first
    #test a node that doesn't exist
    assert_nil ProductCategory.get_parent("23456")
  end
  
  test "get_subcategories method" do  
    #test a node for its subcategories  
    assert_equal 2, ProductCategory.get_subcategories("B29339").uniq.count
    #test a node that doesn't have nay subcategories
    assert_equal [],ProductCategory.get_subcategories("B29342")
  end

  test "Large drop in number of categories" do
    (1..100).each do |offset|
      id = (20000 + offset).to_s
      BestBuyApi.stubs(:get_category).with{ |id_param| id_param == id }.returns({"id" => id, "name" => "Category #{id}"})
      BestBuyApi.stubs(:get_subcategories).with{ |id_param| id_param == id }.returns({"id" => id, "name" => "Category #{id}"} => [])
    end
    
    cats_20 = (1..20).map do |offset| 
      id = (20000 + offset).to_s
      {id => "Category #{id}"}
    end
    cats_45 = (1..45).map do |offset| 
      id = (20000 + offset).to_s
      {id => "Category #{id}"}
    end
    cats_60 = (1..60).map do |offset| 
      id = (20000 + offset).to_s
      {id => "Category #{id}"}
    end
    result_20 = {{"Departments" => "Departments"} => cats_20} 
    result_45 = {{"Departments" => "Departments"} => cats_45} 
    result_60 = {{"Departments" => "Departments"} => cats_60} 
    
    Session.new "BDepartments"
    
    BestBuyApi.stubs(:get_category).with{ |id_param| id_param == "Departments" }.returns({"id" => "Departments", "name" => "Departments"})
    
    # Start with 45 categories
    BestBuyApi.stubs(:get_subcategories).with{ |id_param| id_param == "Departments" }.returns(result_45)
    ProductCategory.update_hierarchy({"Departments" => "Departments"}, "B")
 
    assert_equal(46, ProductCategory.where(retailer: "B").size)
    
    # Drop to 20 categories -- should be no problem, since we do not check for large drop unless original number of 
    # categories >= 50
    BestBuyApi.stubs(:get_subcategories).with{ |id_param| id_param == "Departments" }.returns(result_20)
    
    ProductCategory.update_hierarchy({"Departments" => "Departments"}, "B")
 
    assert_equal(21, ProductCategory.where(retailer: "B").size)
    
    # Start with 60 categories.
    BestBuyApi.stubs(:get_subcategories).with{ |id_param| id_param == "Departments" }.returns(result_60)
    
    ProductCategory.update_hierarchy({"Departments" => "Departments"}, "B")
 
    assert_equal(61, ProductCategory.where(retailer: "B").size)
       
    # Drop to 20 categories, now we should get an exception.
    BestBuyApi.stubs(:get_subcategories).with{ |id_param| id_param == "Departments" }.returns(result_20)
    
   assert_raise BestBuyApi::InvalidFeedError, "ProductCategory.update_hierarchy throws an InvalidFeedError" do
     ProductCategory.update_hierarchy({"Departments" => "Departments"}, "B")
   end
    
    assert_equal(61, ProductCategory.where(retailer: "B").size)
  end  
  
end