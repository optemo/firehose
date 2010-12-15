class Scraper < ActiveRecord::Base
  require 'bestbuy_remix'
  def self.getSKUs(category_id)
    # Just one worker around at all times
    @@b ||= BestBuy::Remix.new
    @@b.category_ids(20218)
  end
end
