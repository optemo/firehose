require 'test_helper'

class TextSpecTest < ActiveSupport::TestCase
  # Replace this with your real tests.
 
  test "if the days_kep is a number" do
    assert_equal("days_kept isn't a number", Search.cleanup_history_data("no") )
  end
 
   
  test "check min_date, max_date" do
    assert_equal("max or min is nil", Search.cleanup_history_data(2) )
  end
  
  
  test "check the number of days_kept" do
    create(:search, created_at: "2011-11-10")
    create(:search, created_at: "2011-11-11")
  
    Search.cleanup_history_data(2)
    assert_equal("Thu, 10 Nov 2011".to_date, Search.minimum(:created_at).to_date)
  end
  
  test "check if the search works" do
     create(:search, created_at: "2011-11-12")
     create(:search, created_at: "2011-11-17")
     create(:search, created_at: "2011-11-20")
    Search.cleanup_history_data(4)
      assert(Search.minimum(:created_at));
     Search.cleanup_history_data(0)
     assert_nil(Search.minimum(:created_at));
  end
end
