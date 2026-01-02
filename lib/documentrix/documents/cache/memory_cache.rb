require 'documentrix/documents/cache/common'

# MemoryCache is an in-memory cache implementation for document embeddings.
#
# This class provides a cache store for document embeddings using a hash-based
# in-memory storage mechanism. It implements the common cache interface
# defined in Documentrix::Documents::Cache::Common and supports operations
# such as setting, retrieving, and deleting cached entries, as well as
# iterating over cached items.
#
# The cache uses a prefix to namespace keys and supports clearing entries
# based on prefixes or specific tags. It is designed to be used as a
# temporary storage mechanism during processing and is not persistent
# across application restarts.
class Documentrix::Documents::MemoryCache
  include Documentrix::Documents::Cache::Common

  # The initialize method sets up the Documentrix::Documents::Cache instance's
  # by setting its prefix attribute to the given value.
  #
  # @param [String] prefix the string to be used as the prefix for this cache
  def initialize(prefix:)
    super(prefix:)
    @data   = {}
  end

  # The [] method retrieves the value associated with the given key from the
  # cache.
  #
  # @param [String] key the key to look up in the cache
  #
  # @return [Object] the cached value, or nil if not found
  def [](key)
    @data[pre(key)]
  end

  # The []= method sets the value for a given key in the cache.
  #
  # @param [String] key the key to set
  # @param [Hash] value the value to associate with the key
  #
  # @return [void]
  def []=(key, value)
    @data[pre(key)] = value
  end

  # The key? method checks if the given key exists in the cache.
  #
  # @param [String] key the key to check for existence
  #
  # @return [TrueClass, FalseClass] true if the key exists, false otherwise
  def key?(key)
    @data.key?(pre(key))
  end

  # The delete method removes the key-value pair from the cache by deleting it
  # from the underlying data structure.
  #
  # @param [String] key the key of the value to be deleted
  #
  # @return [TrueClass, FalseClass] true if the key was found and deleted, false otherwise.
  def delete(key)
    !!@data.delete(pre(key))
  end

  # The size method returns the number of elements in the cache, that is the
  # ones prefixed with `prefix`.
  #
  # @return [ Integer ] The count of elements in the cache.
  def size
    count
  end

  # The clear_all_with_prefix method removes all records from the cache that
  # have keys starting with the prefix `prefix`.
  #
  # @return [ Documentrix::Documents::MemoryCache ] self
  def clear_all_with_prefix
    @data.delete_if { |key, _| key.start_with?(@prefix) }
    self
  end

  # The each method iterates over the cache's keys and values under a given
  # prefix `prefix`.
  #
  # @yield [key, value] Each key-value pair in the cache
  #
  # @return [void]
  def each(&block)
    @data.select { |key,| key.start_with?(@prefix) }.each(&block)
  end

  # The full_each method iterates over the data hash and yields each key-value
  # pair to the given block regardless of the prefix `prefix`.
  #
  # @yield [key, value] Each key-value pair in the data hash
  #
  # @return [void]
  def full_each(&block)
    @data.each(&block)
  end
end
