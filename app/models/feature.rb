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
end
