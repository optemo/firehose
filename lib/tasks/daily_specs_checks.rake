# TODO:
# Task for finding duplicates
# Task for finding incomplete days


# Looks for days missing for all different specs (found according to name) -> no rows exist at all
# Starts at the first day in the database (presumably the first day possible)
task :find_missing_days,[:end_date] => :environment do |t,args|
  require 'date'
  end_date = Date.strptime(args.end_date,"%Y%m%d")
  find_missing_days(end_date)
end

# Finds products with more than one entry per name and date + displays some data
task :find_duplicates => :environment do
  find_duplicate_specs()
end

def find_duplicate_specs
  DailySpec.select("DISTINCT(name)").map(&:name).each do |spec_name| # Find duplicates for each spec_name
    duplicates = DailySpec.select("*,COUNT(sku) as times_repeated").where(:name=>spec_name).group("date,sku").having("COUNT(sku)>1")
    if duplicates.length == 0
      p "No duplicates for spec #{spec_name}"
    else
      p "Duplicates analysis for spec #{spec_name}:"
      repeated_sorted_dates = {}
      duplicates.sort_by{|entry| entry.times_repeated}.reverse.each do |spec|
        if repeated_sorted_dates.key?(spec.times_repeated)
          unless repeated_sorted_dates[spec.times_repeated].include?(spec.date)
            repeated_sorted_dates[spec.times_repeated].push(spec.date)
          end
        else
          repeated_sorted_dates[spec.times_repeated] = [spec.date]
        end
      end
      
  #    top_repeated = duplicates.sort_by{|entry| entry.times_repeated}.reverse.first(100) # rank by number times repeated
  #    skus = DailySpec.select("DISTINCT(sku)").where(:name=>spec_name).group("date,sku").having("COUNT(sku)>1") # distinct skus
  #    dates = DailySpec.select("DISTINCT(date)").where(:name=>spec_name).group("date,sku").having("COUNT(sku)>1") # distinct dates
  #    p "Skus that have duplicates are availble under the 'skus' array"
  #    p "Dates that have duplicates are availble under the 'dates' array"  
  #    p "Most repeated sku/date combos are available under the 'top_repeated' array"  
    
      p "Dates of repeated sku/date combos available as 'repeated_sorted_dates' hash"  
      p "All duplicates are available under the 'duplicates' array"
      p "Debugger is set. If analysis is done press 'q' to quit"
      debugger
      sleep(0.5)
    end
  end
end


def find_missing_days (end_date)
  DailySpec.select("DISTINCT(name)").map(&:name).each do |spec_name|
    days_missing = []
    dates = DailySpec.select("DISTINCT(date)").where(:name=>spec_name).order("date ASC").map(&:date)
    first_date = dates.first
    last_date = dates.last
    last_date = (last_date > end_date) ? end_date : last_date
    (first_date..last_date).each do |date|
      unless dates.include?(date)
        days_missing.push(date.strftime("%Y-%m-%d"))
      end
    end
    (last_date..end_date).each do |date|
      days_missing.push(date.strftime("%Y-%m-%d"))
    end
    p "Days missing for '#{spec_name}':"
    p days_missing.to_s
  end
end