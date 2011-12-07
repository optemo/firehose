class ProductType < ActiveRecord::Base
  has_many :category_id_product_type_maps, :dependent=>:delete_all
  validates_presence_of :name
end
