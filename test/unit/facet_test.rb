require 'test_helper'

class FacetTest < ActiveSupport::TestCase
  
  test "update layout" do
     f1 = create(:facet)
     f2 = create(:facet)
     f3 = create(:facet)
     filter_data = {"0"=>["Binary", "toprated", "Top Rated", "stars", "false"],
                  "1"=>["Heading", "Heading1", "Some Heading", "anything", "true"],
                  "2"=>["Spacer", "space1", "", "", "false"]}
     Facet.update_layout(2, 'filter', filter_data) 
     sorting_data = {"0"=>["Continuous", "displayDate", "Display Date", "", "asc"],
                    "1"=>["Continuous", "saleprice", "Sale Price", "$", "desc"] }
     Facet.update_layout(2, 'sortby', sorting_data)
     compare_data = {"0"=>["Continuous", "regularPrice", "Compare prices", "$$", "false"],
                    "1"=>["Binary", "usb3", "usb3", "", "false"]}
     Facet.update_layout(2, 'show', compare_data)

     assert_nil Facet.find_by_name(f1.name), 'previous facets should be removed when the layout is updated'
     assert_nil Facet.find_by_name(f2.name), 'previous facets should be removed when the layout is updated'
     assert_nil Facet.find_by_name(f3.name), 'previous facets should be removed when the layout is updated'
     
     assert_not_nil Facet.find_by_name_and_used_for('toprated', 'filter'), 'new facet should be present in the database'
     assert_not_nil Facet.find_by_name_and_used_for('saleprice', 'sortby'), 'new facet should be present in the database'
     assert_not_nil Facet.find_by_name_and_used_for('regularPrice', 'show'), 'new facet should be present in the database'

     assert Facet.find_by_feature_type_and_used_for('Spacer', 'filter').value > Facet.find_by_name_and_used_for('toprated', 'filter').value, 'order should be as defined'
     assert Facet.find_by_name_and_used_for('saleprice', 'sortby').value > Facet.find_by_name_and_used_for('displayDate', 'sortby').value, 'order should be as defined'
     assert Facet.find_by_name_and_used_for('usb3', 'show').value > Facet.find_by_name_and_used_for('regularPrice', 'show').value, 'order should be as defined'
     
     assert_equal "stars", I18n.t('camera_bestbuy.filter.toprated.unit'), 'filter unit should be stored as translation'
     assert_equal "Display Date", I18n.t('camera_bestbuy.sortby.displayDate_asc.name'), 'sorby translation should be stored with its direction as translation'
     assert_equal "Compare prices", I18n.t('camera_bestbuy.show.regularPrice.name'), 'compare translation should be stored as translation'
  end
  
  test "get display type" do
    f1 = create(:facet, feature_type: 'Categorical')
    f2 = create(:facet, feature_type: 'Binary')
    f3 = create(:facet, feature_type: 'Continuous')
    
    assert_equal 'Heading', Facet.get_display_type('Heading'), "should get the appropriate display type"
    assert_equal 'Spacer', Facet.get_display_type('Spacer'), "should get the appropriate display type"
    assert_nil Facet.get_display_type('Text'), "should yield no display type mapping"
    assert_not_nil f1.get_display, "categorical facet should have an associated display type"
    assert_not_nil f2.get_display, "binary facet should have an associated display type"
    assert_not_nil f3.get_display, "continuous facet should have an associated display type"
  end
  
  # test "check active" do
  #   # create some facets, etc.
  #   assert true
  # end
  
end