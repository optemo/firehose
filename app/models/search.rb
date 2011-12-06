class Search < ActiveRecord::Base
  # Clean up history data in searches table. Only keep "days" of data
  def self.cleanup_history_data(days_kept)
    # Get the most recently date after which data should be kept
    
      return "days_kept isn't a number" unless days_kept.is_a?(Numeric) 
      max_date = Search.maximum(:created_at)
      min_date = Search.minimum(:created_at)
      
      return "max or min is nil" if max_date.nil? || min_date.nil?
      
      max_date = max_date.to_date
      min_date = min_date.to_date
      # print min and max date (for test)
     # puts "min_date #{min_date}"
     #  puts "max_date #{max_date}"
      
      return "days_kept is less than min_date" if max_date - days_kept.days <= min_date
  
      max_days_kept_date = max_date - days_kept.days
      #for test
     # puts "max_days_kept_date #{max_days_kept_date}"
      
      Search.transaction do
        Search.where("created_at <= ?", max_days_kept_date).delete_all
        Userdatacat.where("created_at <= ?", max_days_kept_date).delete_all
        Userdatabin.where("created_at <= ?", max_days_kept_date).delete_all
        Userdatacont.where("created_at < ?", max_days_kept_date).delete_all
      end
     #for double check if those data correctly were deleted 
      min_date1 = Search.minimum(:created_at)
      return "min is nil" if min_date1.nil?
      #for test
      #puts "min_date #{min_date1.to_date}"
      
  end
end  

#previous code        
=begin 
            max_date = Search.maximum(:created_at).to_date
            min_date = Search.minimum(:created_at).to_date
            return if max_date.nil? || min_date.nil?
            return if max_date - days_kept.days <= min_date



            before_keep_days = days_kept - 1

            1.upto(before_keep_days) do
              temp_max_date = Search.where("created_at < ?", max_date).maximum(:created_at).to_date
              if temp_max_date.nil?
                break
              else
                max_date = temp_max_date
              end
            end
            # Clean up data

            Search.transaction do
              Search.where("created_at < ?", max_date).delete_all
              Userdatacat.where("created_at < ?", max_date).delete_all
              Userdatabin.where("created_at < ?", max_date).delete_all
              Userdatacont.where("created_at < ?", max_date).delete_all
=end  
    
 