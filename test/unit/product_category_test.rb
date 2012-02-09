require 'test_helper'

class ProductCategoryTest < ActiveSupport::TestCase
 
  test "check leaf nodes" do
    leaves = ProductCategory.leaves("B20213")
   #assert true
  end
end