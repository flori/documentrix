require 'documentrix/documents/cache/common'
require 'redis'

# RedisCache is a cache implementation that uses Redis for storing document
# embeddings and related metadata.
#
# This class provides a persistent cache storage solution for document
# embeddings, leveraging Redis's capabilities to store both the embedding
# vectors and associated text data, tags, and source information. It supports
# efficient vector similarity searches through Redis-based operations.
#
# @example
#   cache = Documentrix::Documents::RedisCache.new(prefix: 'docs-', url: 'redis://localhost:6379')
#   cache['key'] = { text: 'example', embedding: [0.1, 0.2, 0.3] }
#   value = cache['key']
class Documentrix::Documents::RedisCache
  include Documentrix::Documents::Cache::Common

  # The initialize method sets up the Documentrix::Documents::RedisCache
  # instance's by setting its prefix attribute to the given value and
  # initializing the Redis client.
  #
  # @param [String] prefix the string to be used as the prefix for this cache
  # @param [String] url the URL of the Redis server (default: ENV['REDIS_URL'])
  # @param [Class] object_class the class of objects stored in Redis (default: nil)
  def initialize(prefix:, url: ENV['REDIS_URL'], object_class:)
    super(prefix:)
    url or raise ArgumentError, 'require redis url'
    @url, @object_class = url, object_class
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
      JSON.parse(value, object_class:)
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
  #
  # @return [Object] self
  def set(key, value)
    redis.set(pre(key), JSON.generate(value))
    value
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

  # Returns an array of collection names that match the given prefix.
  # This is a high-performance override for Redis that only queries keys.
  #
  # @param prefix [String] the prefix to search for in collection names
  # @return [Array<Symbol>] an array of matching collection names
  def collections(prefix)
    unique = Set.new
    redis.scan_each(match: "#{prefix}*") do |key|
      if key =~ /\A#{prefix}(.+)-/
        unique << $1.to_sym
      end
    end
    unique.to_a
  end

  # The clear_all_with_prefix method removes all key-value pairs associated with
  # the given prefix from this cache instance.
  #
  # @return [Documentrix::Documents::RedisCache] self
  def clear_all_with_prefix
    redis.scan_each(match: "#@prefix*") { |key| redis.del(key) }
    defined? super and super
    self
  end

  # Renames all keys that start with <tt>old_prefix</tt> to use
  # <tt>new_prefix</tt>. The method iterates over every affected key,
  # reconstructs the new key name (preserving the part of the key that follows
  # the old prefix), writes the value under the new name, and deletes the old
  # key.
  #
  # @param old_prefix [String] The prefix that currently identifies the target keys.
  # @param new_prefix [String] The prefix that should replace <tt>old_prefix</tt>.
  #
  # @return [self] The cache instance, facilitating method chaining.
  def move_prefix(old_prefix, new_prefix)
    full_each(prefix: '') do |key, value|
      key.start_with?(old_prefix) or next
      unpre_key = unpre(key, prefix: old_prefix)
      redis.set(pre(unpre_key, prefix: new_prefix), JSON.generate(value))
      redis.del(key)
    end
    self
  end

  # The each method iterates over the cache keys with prefix `prefix` and
  # yields each key-value pair to the given block.
  #
  # @yield [key, value] Each key-value pair in the cache
  #
  # @return [self] self
  def each(&block)
    block or return enum_for(__method__)

    redis.scan_each(match: "#@prefix*") { |key| block.(key, self[unpre(key)]) }
    self
  end

  # The full_each method iterates over all records in the cache and yields
  # them to the block.
  #
  # @yield [ key, value ] where key is the record's key and value is the record itself
  def full_each(prefix: 'Documents-', &block)
    block or return enum_for(__method__, prefix:)

    redis.scan_each(match: prefix + ?*) do |key|
      value = redis.get(key) or next
      value = JSON.parse(value, object_class:)
      block.(key, value)
    end
  end
end
