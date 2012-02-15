class ScrapingCorrection < ActiveRecord::Base
  has_many :candidates
  belongs_to :scraping_rule
  
  validates :corrected,  :presence => true
  validates :scraping_rule_id, :presence => true
  validates :product_id, :presence => true
end
