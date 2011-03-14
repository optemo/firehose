module CachingMemcached
  def self.cache_lookup(key)
    if Rails.cache.class != ActiveSupport::Cache::FileStore # We have memcache loaded
      data = Rails.cache.fetch(key) do 
        d = yield
        d[:createdAt] = Time.now if d.class == Hash
        d
      end
      request_time = data.delete(:createdAt)
      debugger if request_time.nil?
      if (Time.now - request_time).to_f > 20 # If the data is over 20 hours old (ignoring the time zone issues, this should work every day)
        data = yield
      end
      data
    else
      yield
    end
  end
end
