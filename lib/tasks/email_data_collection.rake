#                                whether or not running daily updates of database
#                                                 |
task :email_data_collection, [:spec, :table, :daily_updates, :start_date, :end_date] => :environment do |t,args|
  require 'email_data_collection'
  args.with_defaults(:start_date=>false,:end_date=>false)
  daily_updates = (args.daily_updates == "false") ? false : true
  task_data = set_needed_fields(args.spec, args.table)
  dates = parse_dates(args.start_date, args.end_date,task_data[:first_possible_date])
  save_email_data(task_data, daily_updates, dates.first, dates.last)
end

# Checks the date inputs and sets the appropriate dates
def parse_dates (first_day, last_day,first_day_possible)
  if first_day == "" ||  first_day == false #This lets the user omit inputting a start date. Eg: [daily_spec,false,,20110801]
    start_date = false
  else
    start_day = Date.strptime(first_day,"%Y%m%d")
    first_day_possible = Date.strptime(first_day_possible,"%d-%b-%Y")
    if start_day < first_day_possible # if the date wanted preceded the first day available in the emails, use the latter
      start_date = first_day_possible
    else
      start_date = start_day
    end
  end
  if last_day == false
    end_date = false
  else
    end_date = Date.strptime(last_day, "%Y%m%d")
  end
  return [start_date,end_date]
end