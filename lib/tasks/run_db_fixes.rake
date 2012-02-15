task :set_missing_ids => :environment do
    
    require 'db_fixes'
    #Need to Specify Database table to use in function set_missing_ids()
    set_missing_ids()
  
end