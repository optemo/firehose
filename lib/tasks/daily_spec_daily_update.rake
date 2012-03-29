# IF TRULY WANT 'DAYS_BACK' days available, will need to manually remove to <= 'DAYS_BACK' days

DAYS_BACK = 60

task :update_daily_specs,[:date] => :environment do |t,args|
  require 'temp_email_collection'
  
  date = Date.strptime(args.date, "%Y%m%d")
  before_whole = Time.now

  # Load online_orders based on previous day's instock
  save_email_data({:first_possible_date => "09-Sep-2011", :spec => "online_orders", :table => "daily_specs"}, true, date, date)

  # Load pageviews based on previous day's products (all)
  save_email_data({:first_possible_date => "29-Oct-2011", :spec => "pageviews"}, true, date, date)
  
  # Delete oldest record if daily_specs goes back more than 'DAYS_BACK' days
  dates_saved = DailySpec.select("DISTINCT(date)").order("date ASC").map(&:date)
  unless dates_saved.length <= DAYS_BACK 
    DailySpec.delete_all(:date => dates_saved.first)
  end

  after_whole = Time.now
  p "Total time for #{date}: #{after_whole-before_whole} s"
end

