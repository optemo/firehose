class CategoryIdProductTypeMap < ActiveRecord::Base
  belongs_to :product_type
  validates_presence_of :product_type_id
  validates_presence_of :category_id
  validates_presence_of :name
  validates_uniqueness_of :category_id, :scope => :product_type_id
  validates_format_of :category_id, :with => /\d{5,}/
end