require 'test_helper'

class TranslationTest < ActiveSupport::TestCase
  test "the truth" do
    I18n.backend.store_translations(:en, ProductType.first.name => { 'test_string' => "My translation" } )
    I18n.backend.store_translations(:fr, ProductType.first.name => { 'test_string' => "Aujourd'hui" } )
    I18n.locale = :en
    assert_equal "My translation", I18n.t(ProductType.first.name + ".test_string"), 'should retrieve translation for current locale'
    I18n.locale = :fr
    assert_equal "Aujourd'hui", I18n.t(ProductType.first.name + ".test_string"), 'should retrieve translation for current locale'
    assert true
  end
end
