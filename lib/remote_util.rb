# A module containing useful patterns relating to remote web service calls.
module RemoteUtil
  # Attempt the given block a specified number of times, with specified interval between retries.
  # Exceptions belonging to the classes passed in the exceptions list are caught and result in a 
  # retry. If the maximum number of retries is reached, then any exception raised on the final 
  # attempt is passed to the caller.
  #
  # params - Hash with the following optional elements:
  #   :max_tries - Maximum number of times to retry (default is 3)
  #   :interval - Interval between retries, in seconds (default 15)
  #   :exceptions - Array of exception classes that will result in retries. Other types of exceptions
  #                 will be passed to the caller (default is Exception)
  #
  # { |except| ... } - The code to be attempted. If this is a retry, the block is invoked with the 
  #                    exception that caused the retry.
  # 
  # If an attempt succeeds, returns the value of the block.
  def RemoteUtil.do_with_retry(params = {}) 
    params = {max_tries: 3, interval: 15, exceptions: [Exception]}.merge(params)
    exceptions = Array(params[:exceptions])
    max_tries = params[:max_tries]
    interval = params[:interval]

    tries = 0
    last_except = nil
    begin
      yield last_except
    rescue Exception => except
      tries += 1
      last_except = except
      if exceptions.index { |e| except.is_a? e } and tries < max_tries
        if interval > 0 
          sleep interval
        end
        retry
      end
      raise
    end
  end
end


      


