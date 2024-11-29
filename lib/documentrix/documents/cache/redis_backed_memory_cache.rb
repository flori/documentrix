require 'redis'

class Documentrix::Documents
  class RedisBackedMemoryCache < MemoryCache

    # The initialize method sets up the RedisBackedMemoryCache cache by
    # creating a new instance and populating it with data from the internally
    # created RedisCache.
    #
    # @param prefix [String] The prefix for keys in the Redis cache
    # @param url [String] The URL of the Redis server (default: ENV['REDIS_URL'])
    # @param object_class [Class] The class to use for deserializing values from Redis (default: nil)
    #
    # @raise [ArgumentError] If the redis_url environment variable is not set
    def initialize(prefix:, url: ENV['REDIS_URL'], object_class: nil)
      super(prefix:)
      url or raise ArgumentError, 'require redis url'
      @url, @object_class = url, object_class
      @redis_cache = Documentrix::Documents::RedisCache.new(prefix:, url:, object_class:)
      @redis_cache.extend(Documentrix::Documents::Cache::Records::RedisFullEach)
      @redis_cache.full_each { |key, value| @data[key] = value }
    end

    attr_reader :object_class # the class of objects stored in the cache

    # The redis method returns the Redis client instance used by the cache.
    #
    # @return [Redis] The Redis client instance
    def redis
      @redis_cache.redis
    end

    # The set method sets the value for a given key in memory and in Redis.
    #
    # @param [String] key the key to be set
    # @param [Hash] value the hash containing the data to be stored
    def []=(key, value)
      super
      redis.set(pre(key), JSON(value))
    end

    # The delete method removes a key from the cache by calling Redis's del
    # method and then calling the superclass's delete method.
    #
    # @param [String] key the key to be deleted
    #
    # @return [FalseClass, TrueClass] true if the key was successfully deleted, false otherwise.
    def delete(key)
      result = redis.del(pre(key))
      super && result == 1
    end

    # The clear method deletes all keys from the cache by scanning redis for
    # keys that match the prefix `prefix` and then deleting them, then it does
    # the same for the MemoryCache by calling its super.
    #
    # @return [self] self
    def clear
      redis.scan_each(match: "#@prefix*") { |key| redis.del(key) }
      super
      self
    end
  end
end
