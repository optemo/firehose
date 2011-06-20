class ProductType < ActiveRecord::Base
  has_many :urls
  has_many :headings
  has_many :features, :through => :headings

  validates_presence_of :name
  validates_presence_of :category_id
end
