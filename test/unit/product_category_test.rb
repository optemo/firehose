ENV["RAILS_ENV"] = "test"
require File.expand_path('../../../config/environment', __FILE__)
require 'rails/test_help'

class ProductCategoryTest < ActiveSupport::TestCase
 
  test "test get_children and leaves methods" do  
    assert_equal [], ProductCategory.leaves("B28597")
    assert_equal 3, ProductCategory.leaves("B30317a").count
  end
  
  test "test get_ancestors method" do  
    assert_equal [], ProductCategory.get_ancestors("BDepartments", "bestbuy")
    assert_nil ProductCategory.get_ancestors("BDepart", "bestbuy")
    assert_equal "B20001", ProductCategory.get_ancestors("B21202", "bestbuy", 2).first.product_type
    assert ProductCategory.get_ancestors("B21202", "bestbuy")
  end
  
  test "test get_parents method" do  
     assert_equal "B30317a", ProductCategory.get_parent("B29182", "bestbuy").product_type
     assert_nil ProductCategory.get_parent("23456", "futureshop")
  end
  
   test "test get_subcategories method" do  
       assert ProductCategory.get_subcategories("B20001", "bestbuy")
       assert_equal [],ProductCategory.get_subcategories("B30938", "bestbuy")
   end
  
end