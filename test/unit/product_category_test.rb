ENV["RAILS_ENV"] = "test"
require File.expand_path('../../../config/environment', __FILE__)
require 'rails/test_help'

class ProductCategoryTest < ActiveSupport::TestCase
 
  test "test get_children and leaves methods" do  
    #test a node without any children
    assert_equal [], ProductCategory.leaves("B28597")
    #test a single node with one level of children
    #B30317a with l_id: 53 ,r_id: 60
    assert_equal 3, ProductCategory.leaves("B30317a").count
    #test an array of nodes with more than one level children
    #B26217 with l_id:83, r_id:114, B29339 with L_id:2837, r_id:2844
    assert_equal 16,  ProductCategory.leaves(["B26217","B29339"]).count
  end
  
  test "test get_ancestors method" do  
    #test a node with out any ancestors
    assert_equal [], ProductCategory.get_ancestors("BDepartments")
    #test a node that doesn't exist
    assert_nil ProductCategory.get_ancestors("BDepart")
    #test an array of nodes for  their ancestors at a specific level
    assert_equal ["B20001","B20002"], ProductCategory.get_ancestors(["B21202","B20404"], 2).uniq
    #test a node for all of its ancestors
    assert_equal 2, ProductCategory.get_ancestors("B21202").uniq.count
  end
  
  test "test get_parents method" do  
    #test a node with for its parent
     assert_equal "B30317a", ProductCategory.get_parent("B29182").first
     #test a node that doens't exist
     assert_nil ProductCategory.get_parent("23456")
  end
  
   test "test get_subcategories method" do  
      #test a node for its subcategories  
      assert_equal 14, ProductCategory.get_subcategories("B20001").uniq.count
      #test a node that doesn't have nay subcategories
      assert_equal [],ProductCategory.get_subcategories("B30938")
   end
  
end