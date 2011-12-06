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
    
    assert_equal("days_kept is less than min_date", Search.cleanup_history_data(2) )
  end
  
  test "check if the search works" do
     create(:search, created_at: "2011-11-12")
     create(:search, created_at: "2011-11-17")
     create(:search, created_at: "2011-11-20")
     assert_nil(Search.cleanup_history_data(4));
  end
end
