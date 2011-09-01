desc "Download BestBuy Product Report email attachment"
task :product_orders => :environment do
  Session.new
  require 'email_attachment'
  product_orders(fskus)
end