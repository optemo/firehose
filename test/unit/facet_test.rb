require 'test_helper'

class FacetTest < ActiveSupport::TestCase
  
  setup do
    Session.new "B22474"
  end
  
  test "update layout" do
     f1 = create(:facet)
     f2 = create(:facet)
     f3 = create(:facet)
     
     filter_data = {"0"=>["100", "Binary", "toprated", "Top Rated", "stars", "boldlabel","false","B20222"],
                  "1"=>["101", "Heading", "status", "Status", "", "","false"],
                  "2"=>["102", "Spacer", "space1", "", "", "false","false"]}
     Facet.update_layout("B20218", 'filter', filter_data)
     sorting_data = {"0"=>["103", "Continuous", "displayDate", "Display Date", "", "asc","false"],
                    "1"=>["104", "Continuous", "saleprice", "Sale Price", "$", "desc","false"] }
     Facet.update_layout("B20218", 'sortby', sorting_data)
     compare_data = {"0"=>["105", "Continuous", "regularPrice", "Compare prices", "$$", "false","false"],
                    "1"=>["106", "Binary", "usb3", "usb3", "", "false","false"]}
     Facet.update_layout("B20218", 'show', compare_data)

     assert_nil Facet.find_by_name(f1.name), 'previous facets should be removed when the layout is updated'
     assert_nil Facet.find_by_name(f2.name), 'previous facets should be removed when the layout is updated'
     assert_nil Facet.find_by_name(f3.name), 'previous facets should be removed when the layout is updated'
     
     assert_not_nil Facet.find_by_name_and_used_for('toprated', 'filter'), 'new facet should be present in the database'
     assert_not_nil Facet.find_by_name_and_used_for('saleprice', 'sortby'), 'new facet should be present in the database'
     assert_not_nil Facet.find_by_name_and_used_for('regularPrice', 'show'), 'new facet should be present in the database'

     assert Facet.find_by_feature_type_and_used_for('Spacer', 'filter').value > Facet.find_by_name_and_used_for('toprated', 'filter').value, 'order should be as defined'
     assert Facet.find_by_name_and_used_for('saleprice', 'sortby').value > Facet.find_by_name_and_used_for('displayDate', 'sortby').value, 'order should be as defined'
     assert Facet.find_by_name_and_used_for('usb3', 'show').value > Facet.find_by_name_and_used_for('regularPrice', 'show').value, 'order should be as defined'
     
     assert_not_nil Facet.find_by_feature_type_and_name('Ordering', "B20222"), "ordering facet should be created"
     filter_data[0] = ["100", "Binary", "toprated", "Top Rated", "stars", "boldlabel","true"]
     Facet.update_layout("B20218", 'filter', filter_data)
     assert_nil Facet.find_by_feature_type_and_name('Ordering', "B20222"), "ordering should be cleared"
     
     assert_equal "stars", I18n.t('B20218.filter.toprated.unit'), 'filter unit should be stored as translation'
     assert_equal "Display Date", I18n.t('B20218.sortby.displayDate_asc.name'), 'sorby translation should be stored with its direction as translation'
     assert_equal "Compare prices", I18n.t('B20218.show.regularPrice.name'), 'compare translation should be stored as translation'
  end
  
  test "get display type" do
    f1 = create(:facet, feature_type: 'Categorical')
    f2 = create(:facet, feature_type: 'Binary')
    f3 = create(:facet, feature_type: 'Continuous', ui: 'slider')
    
    assert_equal 'Heading', Facet.get_display_type('Heading'), "should get the appropriate display type"
    assert_equal 'Spacer', Facet.get_display_type('Spacer'), "should get the appropriate display type"
    assert_nil Facet.get_display_type('Text'), "should yield no display type mapping"
    assert_not_nil f1.get_display, "categorical facet should have an associated display type"
    assert_not_nil f2.get_display, "binary facet should have an associated display type"
    assert_equal 'Slider', f3.get_display, "custom display type set"
  end
  
end