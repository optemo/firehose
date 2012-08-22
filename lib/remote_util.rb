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
  # { |is_retry| ... } - The code to be attempted. This block is invoked with a boolean is_retry
  #                      parameter indicating whether at least one try has already occurred.
  # 
  # If an attempt succeeds, returns the value of the block.
  def RemoteUtil.do_with_retry(params = {}) 
    params = {max_tries: 3, interval: 15, exceptions: [Exception]}.merge(params)
    exceptions = Array(params[:exceptions])
    max_tries = params[:max_tries]
    interval = params[:interval]

    tries = 0
    begin
      yield (tries > 0)
    rescue Exception => except
      tries += 1
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


      


