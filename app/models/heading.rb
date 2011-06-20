class Heading < ActiveRecord::Base
  belongs_to :product_type
  has_many :features
end
