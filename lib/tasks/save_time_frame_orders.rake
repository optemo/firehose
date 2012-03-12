task :save_time_frame_orders, [:num_days_back] => :environment do |t, args|
  require 'write_sales'
  
  #change default number of days to 30 after testing done
  args.with_defaults(:num_days_back => "30")

  write_sale_in_time_frame(args.num_days_back.to_i)
  
end
