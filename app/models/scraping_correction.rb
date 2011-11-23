class ScrapingCorrection < ActiveRecord::Base
  has_many :candidates
  belongs_to :scraping_rule
end
