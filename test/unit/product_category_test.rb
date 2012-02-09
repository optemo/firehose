require 'test_helper'

class ProductCategoryTest < ActiveSupport::TestCase
 
  test "check leaf nodes" do
    # check that the equivalence model has 3 records
    leaves = ProductCategory.leaves("B20213")
  end
end