
task :daily_sales_collection, [:table,:check_exist,:start_date,:end_date] => :environment do |t,args|
  require 'daily_sales'
  args.with_defaults(:start_date=>false,:end_date=>false)
  check_exist = args.check_exist == "true" ? true : false
  dates = parse_dates(args.start_date, args.end_date)
  save_daily_sales(args.table, check_exist, dates.first, dates.last)
  #generate_daily_graphs()
end  
 
task :daily_pageviews_collection, [:check_exist,:start_date,:end_date] => :environment do |t,args|
  require 'daily_page_views'
  args.with_defaults(:start_date=>false,:end_date=>false)
  check_exist = args.check_exist == "true" ? true : false
  dates = parse_dates(args.start_date, args.end_date)
  save_daily_pageviews(check_exist, dates.first, dates.last)
end  

# Checks the date inputs and sets the appropriate dates
def parse_dates (first_day, last_day)
  if first_day == "" ||  first_day == false #This lets the user omit inputting a start date. Eg: [daily_spec,false,,20110801]
    start_date = false
  else
    start_date = Date.strptime(first_day,"%Y%m%d")
  end
  if last_day == false
    end_date = false
  else
    end_date = Date.strptime(last_day, "%Y%m%d")
  end
  return [start_date,end_date]
end
