require 'test_helper'

class SearchTest < ActiveSupport::TestCase
  
  test "Check the number of days kept" do
    three_days_ago = Time.now.utc - 3 * 24 * 60 * 60
    now = Time.now.utc
    old_search = create(:search, updated_at: three_days_ago)
    create(:userdatacat, search: old_search)
    create(:userdatacont, search: old_search)
    create(:userdatabin, search: old_search)

    old_search = create(:search, updated_at: three_days_ago)
    create(:userdatacat, search: old_search)
    create(:userdatacont, search: old_search)
    create(:userdatabin, search: old_search)

    new_search = create(:search, updated_at: now)
    create(:userdatacat, search: new_search)
    create(:userdatacont, search: new_search)
    create(:userdatabin, search: new_search)

    assert_equal 3, Search.all.size
    assert_equal 3, Userdatacat.all.size
    assert_equal 3, Userdatacont.all.size
    assert_equal 3, Userdatabin.all.size
  
    Search.cleanup_history_data(1)

    assert_equal 1, Search.all.size, "Two searches were cleaned up"
    assert_equal 1, Userdatacat.all.size, "Userdatacats were cleaned up"
    assert_equal 1, Userdatacont.all.size, "Userdataconts were cleaned up"
    assert_equal 1, Userdatabin.all.size, "Userdatabins were cleaned up"
    assert_equal new_search.id, Search.all[0].id, "The recent search was not cleaned up"
  end

end
