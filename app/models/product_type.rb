class ProductType < ActiveRecord::Base
  has_many :category_id_product_type_maps, :dependent=>:delete_all
  accepts_nested_attributes_for :category_id_product_type_maps

  validates_presence_of :name
end
