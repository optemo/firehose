task :save_time_frame_orders => :environment do
  require 'write_sales'
  write_sale_in_time_frame(6)
  
end
