class Result < ActiveRecord::Base
  has_many :delinquents
  has_many :candidates
  has_and_belongs_to_many :scraping_rules
end
