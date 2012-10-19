class Search < ActiveRecord::Base
  has_many :userdatacats, :dependent=>:delete_all
  has_many :userdatabins, :dependent=>:delete_all
  has_many :userdataconts, :dependent=>:delete_all
 
  # Clean up history data in searches table. Only keep records which have been updated within
  # the last 'days_kept' days.
  def self.cleanup_history_data(days_kept)
    cleanup_time = Time.now.utc - days_kept * 24 * 60 * 60
    Search.where("updated_at < ?", cleanup_time).destroy_all
  end
end
