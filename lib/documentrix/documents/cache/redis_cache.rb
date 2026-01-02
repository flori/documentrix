require 'documentrix/documents/cache/common'
require 'redis'

class Documentrix::Documents::RedisCache
  include Documentrix::Documents::Cache::Common
  include Documentrix::Documents::Cache::Records::RedisFullEach

  # The initialize method sets up the Documentrix::Documents::RedisCache
  # instance's by setting its prefix attribute to the given value and
  # initializing the Redis client.
  #
  # @param [String] prefix the string to be used as the prefix for this cache
  # @param [String] url the URL of the Redis server (default: ENV['REDIS_URL'])
  # @param [Class] object_class the class of objects stored in Redis (default: nil)
  # @param [Integer] ex the expiration time in seconds (default: nil)
  def initialize(prefix:, url: ENV['REDIS_URL'], object_class: nil, ex: nil)
    super(prefix:)
    url or raise ArgumentError, 'require redis url'
    @url, @object_class, @ex = url, object_class, ex
  end

  attr_reader :object_class # the class of objects stored in the cache

  # The redis method returns an instance of Redis client
  #
  # @return [Redis] An instance of Redis client
  def redis
    @redis ||= Redis.new(url: @url)
  end

  # The [](key) method retrieves the value associated with the given key from Redis.
  #
  # @param [String] key the string representation of the key
  #
  # @return [Object, nil] the retrieved value if it exists in Redis, or nil otherwise
  def [](key)
    value = redis.get(pre(key))
    unless value.nil?
      object_class ? JSON(value, object_class:) : JSON(value)
    end
  end

  # The []= method sets the value associated with the given key in this cache instance.
  #
  # @param [String] key the string representation of the key
  # @param [Object] value the object to be stored under the given key
  #
  # @return [Object] self
  def []=(key, value)
    set(key, value)
  end

  # The set method sets the value associated with the given key in this cache instance.
  #
  # @param [String] key the string representation of the key
  # @param [Object] value the object to be stored under the given key
  # @option ex [Integer] ex the expiration time in seconds (default: nil)
  #
  # @return [Object] self
  def set(key, value, ex: nil)
    ex ||= @ex
    if !ex.nil? && ex < 1
      redis.del(pre(key))
    else
      redis.set(pre(key), JSON.generate(value), ex:)
    end
    value
  end

  # The ttl method returns the time-to-live (TTL) value for the given key
  #
  # @param [String] key the string representation of the key
  #
  # @return [Integer, nil] the TTL value if it exists in Redis, or nil otherwise
  def ttl(key)
    redis.ttl(pre(key))
  end

  # The key? method checks if the given key exists in Redis by calling the
  # redis.exists? method
  #
  # @param [String] key the string representation of the key
  #
  # @return [FalseClass, TrueClass] true if the key exists, false otherwise
  def key?(key)
    !!redis.exists?(pre(key))
  end

  # The delete method removes the key-value pair associated with the given key
  # from this cache instance.
  #
  # @param [String] key the string representation of the key
  #
  # @return [FalseClass, TrueClass] true if the key was deleted successfully, false otherwise
  def delete(key)
    redis.del(pre(key)) == 1
  end

  # The size method returns the total number of keys stored in this cache
  # instance, that is the ones with the prefix `prefix`.
  #
  # @return [Integer] The total count of keys
  def size
    s = 0
    redis.scan_each(match: "#@prefix*") { |key| s += 1 }
    s
  end

  # The clear_all_with_prefix method removes all key-value pairs associated
  # with the given prefix from this cache instance.
  #
  # @return [Documentrix::Documents::RedisCache] self
  def clear_all_with_prefix
    redis.scan_each(match: "#@prefix*") { |key| redis.del(key) }
    defined? super and super
    self
  end

  # The each method iterates over the cache keys with prefix `prefix` and
  # yields each key-value pair to the given block.
  #
  # @yield [key, value] Each key-value pair in the cache
  #
  # @return [self] self
  def each(&block)
    redis.scan_each(match: "#@prefix*") { |key| block.(key, self[unpre(key)]) }
    self
  end
end
