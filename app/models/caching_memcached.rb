module CachingMemcached
  def self.cache_lookup(key)
    if Rails.cache.class == ActiveSupport::Cache::MemCacheStore # We have memcache loaded
      data = Rails.cache.fetch(key) { yield }
      request_time = data["time"]
      request_time = data["product"]["time"] unless request_time
      if (Time.now - Time.parse(request_time)).to_f > 20 # If the data is over 20 hours old (ignoring the time zone issues, this should work every day)
        data = yield
      end
      data
    else
      yield
    end
  end
end
