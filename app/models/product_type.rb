class ProductType < ActiveRecord::Base
  has_many :urls, :dependent=>:delete_all
  has_many :headings, :dependent=>:delete_all
  has_many :features, :through => :headings
  has_many :category_id_product_type_maps
  accepts_nested_attributes_for :category_id_product_type_maps

  validates_presence_of :name
end
