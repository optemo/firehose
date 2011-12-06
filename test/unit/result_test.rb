require 'test_helper'

class ResultTest < ActiveSupport::TestCase
  # Replace this with your real tests.
  
  setup do
     Session.new
   end

  test "the truth" do
    assert true
  end
  
  test "upkeep_post" do 
    p1 = create(:product)
    p2 = create(:product)
    p3 = create(:product)
     create(:bin_spec, name:"featured")
    create(:bin_spec, name:"featured")
  
  end
end
