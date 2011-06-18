class ProductTypeUrl < ActiveRecord::Base
  belongs_to :product_type
  validates_presence_of :url
end
