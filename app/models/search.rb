class Search < ActiveRecord::Base
  # Clean up history data in searches table. Only keep "days" of data
  def self.cleanup_history_data(days_kept)
    # Get the most recently date after which data should be kept
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
    end
  end
end