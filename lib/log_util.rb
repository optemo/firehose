# A module containing utility functions related to logging.
module LogUtil

  # Returns a timestamp suitable for including in a log message.
  def LogUtil.timestamp 
    Time.now.strftime("%Y-%m-%d %H:%M:%S")
  end

end

