class ProductTypeHeading < ActiveRecord::Base
  belongs_to :product_type
  has_many :product_type_features
end
