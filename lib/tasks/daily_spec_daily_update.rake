# IF TRULY WANT 'DAYS_BACK' days available, will need to manually remove to <= 'DAYS_BACK' days

# When call this from automated task, give it as argument Date.today.prev_day (test this though)

DAYS_BACK = 60

task :save_daily_instock => :environment do |t,args|
  # this task saves the skus of the products that are instock in the database
  # into daily_specs with yesterday's date
  # assumption: this is run before the daily products update for today
  yesterday = Date.today.prev_day
  
  specs_to_save = []
  Product.where(:instock => 1).each do |prod|
    sku = prod.sku         
    product_type = CatSpec.where(:name => "product_type", :product_id => prod.id).first.try(:value)
    specs_to_save.push(DailySpec.new :sku => sku, :name => 'instock', :spec_type => 'bin', :value_bin => true, :product_type => product_type, :date => yesterday)
  end
  DailySpec.import specs_to_save # is this the right syntax?  
  # also delete instock specs older than 60 days here?
end

task :update_daily_specs => :environment do |t,args|
  # Check whether table is going to skip a day. Because this task will be run before the update task, 
  # if it hasn't been run in a while the products table is out of date)
  date = Date.today.prev_day
  
  yesterday_daily_spec_with_instock = DailySpec.where(:name => 'instock', :date => date).limit(1)
  if yesterday_daily_spec_with_instock.empty?  
    p "Unsuccessful: DailySpec is missing yesterday's instock data."
    raise "DailySpec is missing yesterday's instock data."
  end

  require 'email_data_collection'
  
  before_whole = Time.now

  # Load online_orders based on previous day's instock
  save_email_data({:first_possible_date => "09-Sep-2011", :spec => "online_orders", :table => "daily_specs"}, true, date, date)

  # Load pageviews based on previous day's products (all)
  save_email_data({:first_possible_date => "29-Oct-2011", :spec => "pageviews", :table => "daily_specs"}, true, date, date)
  
  # Delete all records if they are more than DAYS_BACK days when sorted in daily specs
  dates_saved = DailySpec.select("DISTINCT(date)").order("date ASC").map(&:date)
  unless dates_saved.length <= DAYS_BACK 
    DailySpec.delete_all(:date => dates_saved[0, dates_saved.length-DAYS_BACK])
  end

  after_whole = Time.now
  p "Total time for #{date}: #{after_whole-before_whole} s"
end

