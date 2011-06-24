class Heading < ActiveRecord::Base
  belongs_to :product_type
  has_many :features, :dependent => :delete_all
end
