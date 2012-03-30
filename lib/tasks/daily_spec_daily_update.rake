# IF TRULY WANT 'DAYS_BACK' days available, will need to manually remove to <= 'DAYS_BACK' days

# When call this from automated task, give it as argument Date.today.prev_day (test this though)

DAYS_BACK = 60

task :update_daily_specs => :environment do |t,args|
  # Check whether table is going to skip a day. Because this task will be run before the update task, 
  # if it hasn't been run in a while the products table is out of date)
  date = Date.today.prev_day
  last_date_in_table = DailySpec.select("DISTINCT(date)").order("date DESC").limit(1).first.date
  unless last_date_in_table == date.prev_day
    raise "DailySpec is missing one or more days of data. Please use the catchup rake task."
  end

  require 'email_data_collection'
  
  before_whole = Time.now

  # Load online_orders based on previous day's instock
  save_email_data({:first_possible_date => "09-Sep-2011", :spec => "online_orders", :table => "daily_specs"}, true, date, date)

  # Load pageviews based on previous day's products (all)
  save_email_data({:first_possible_date => "29-Oct-2011", :spec => "pageviews", :table => "daily_specs"}, true, date, date)
  
  # Delete oldest record if daily_specs goes back more than 'DAYS_BACK' days
  dates_saved = DailySpec.select("DISTINCT(date)").order("date ASC").map(&:date)
  unless dates_saved.length <= DAYS_BACK 
    DailySpec.delete_all(:date => dates_saved.first)
  end

  after_whole = Time.now
  p "Total time for #{date}: #{after_whole-before_whole} s"
end

