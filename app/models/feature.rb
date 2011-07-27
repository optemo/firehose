class Feature < ActiveRecord::Base
  belongs_to :heading, :include => :product_type
  validates_presence_of :name
  validates_presence_of :heading_id
  validates_presence_of :feature_type
  validates_presence_of :utility_weight
  validates_presence_of :cluster_weight
  validates_format_of :utility_weight, :with=>/\d+/
  validates_format_of :cluster_weight, :with=>/\d+/
  validates_inclusion_of :feature_type, :in => %w(Continuous Binary Categorical)
  def self.count_products(p_type_name = nil)
    product_type_name = (Session.product_type ||= 'camera_bestbuy') if p_type_name.nil?
    product_type_name ||= p_type_name

    features_to_save = []
    Feature.all.each do |feature|
      if feature.heading.product_type.name == product_type_name
        products_counts = 0
        if feature.feature_type == 'Binary'
          products_counts = BinSpec.count(:conditions =>["name=? and bin_specs.product_type=? and value is not null and value > 0",  feature.name, product_type_name], :joins => "INNER JOIN products on products.id=product_id and products.instock=1")
          feature.has_products = (products_counts > 0 ? 1 : 0)
          features_to_save << feature

        end
      end
    end
    print features_to_save.size
    Feature.import features_to_save, :on_duplicate_key_update => [:has_products] if features_to_save.size > 0
  end
end
