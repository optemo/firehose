class Candidate < ActiveRecord::Base
  belongs_to :result
  belongs_to :scraping_rule
  belongs_to :scraping_correction
end
