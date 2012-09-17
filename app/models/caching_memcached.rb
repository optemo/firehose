module CachingMemcached
  #Version where keys expire - this does not seem to be working
  #def self.cache_lookup(key)
  #  if Rails.cache.class != ActiveSupport::Cache::FileStore # We have memcache loaded
  #    data = Rails.cache.fetch(key) do 
  #      d = yield
  #      d[:createdAt] = Time.now if d.class == Hash
  #      d
  #    end
  #    data = data.dup
  #    request_time = data.delete(:createdAt)
  #    debugger if request_time.nil?
  #    if (Time.now - request_time).to_f > 20 # If the data is over 20 hours old (ignoring the time zone issues, this should work every day)
  #      data = yield
  #    end
  #    data
  #  else
  #    yield
  #  end
  #end
  
  #Keys should not be longer than 250 chars
  def self.cache_lookup(key)
    if Rails.cache.class != ActiveSupport::Cache::FileStore # We have memcache loaded
      #Rails.cache.fetch(key) { yield }
      #Maximum key length in memcached is 250
      key = Digest::MD5.hexdigest(key) if key.size > 250
      data = Rails.cache.read(key)
      if data.nil?
        data = yield
        Rails.cache.write(key,data)
        data
      else
        data.dup
      end
    else
      yield
    end
  end
end
