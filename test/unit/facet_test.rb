require 'test_helper'

class FacetTest < ActiveSupport::TestCase
  
  test "update layout" do
     f1 = create(:facet)
     f2 = create(:facet)
     f3 = create(:facet)
     filter_data = {"0"=>["Binary", "toprated", "toprated", "false"],
                  "1"=>["Heading", "status", "status", "true"]}
     Facet.update_layout(2, 'filter', filter_data) 
     sorting_data = {"0"=>["Continuous", "displayDate", "displayDate", "asc"],
                    "1"=>["Continuous", "saleprice_factor", "saleprice_factor", "desc"] }
     Facet.update_layout(2, 'sortby', sorting_data)
     compare_data = {"0"=>["Categorical", "color", "color", "false"],
                    "1"=>["Continuous", "saleprice_factor", "saleprice_factor", "true"] }
     Facet.update_layout(2, 'show', compare_data)

     assert_nil Facet.find_by_name(f1.name), 'previous facets should be removed when the layout is updated'
     assert_nil Facet.find_by_name(f2.name), 'previous facets should be removed when the layout is updated'
     assert_nil Facet.find_by_name(f3.name), 'previous facets should be removed when the layout is updated'
     
     assert_not_nil Facet.find_by_name_and_used_for('status', 'filter'), 'new facet should be present in the database'
     assert_not_nil Facet.find_by_name_and_used_for('displayDate', 'sortby'), 'new facet should be present in the database'
     assert_not_nil Facet.find_by_name_and_used_for('color', 'show'), 'new facet should be present in the database'

     assert Facet.find_by_name_and_used_for('status', 'filter').value > Facet.find_by_name_and_used_for('toprated', 'filter').value, 'order should be as definded'
     assert Facet.find_by_name_and_used_for('saleprice_factor', 'sortby').value > Facet.find_by_name_and_used_for('displayDate', 'sortby').value, 'order should be as definded'
     assert Facet.find_by_name_and_used_for('saleprice_factor', 'show').value > Facet.find_by_name_and_used_for('color', 'show').value, 'order should be as definded'
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