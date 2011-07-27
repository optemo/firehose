class Heading < ActiveRecord::Base
  belongs_to :product_type
  has_many :features, :dependent => :delete_all
  validates_acceptance_of :name
  validates_acceptance_of :product_type_id
  validates_format_of :show_order, :with=>/\d+/
end
