require 'test_helper'

class TextSpecTest < ActiveSupport::TestCase
  
  setup do
     Session.new
   end

  test "test get_relation" do
    ProductSibling.get_relations
  end
end