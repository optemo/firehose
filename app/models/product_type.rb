class ProductType < ActiveRecord::Base
  has_many :urls, :dependent=>:delete_all
  has_many :headings, :dependent=>:delete_all
  has_many :features, :through => :headings

  validates_presence_of :name
  validates_presence_of :category_id
end
