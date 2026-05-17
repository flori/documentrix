# Common interface for document caches
#
# This module defines the standard interface that all document cache
# implementations must adhere to. It provides shared functionality for managing
# cached document embeddings, including methods for setting, retrieving, and
# deleting cache entries, as well as querying and filtering cached data based
# on tags and similarity searches.
#
# The module includes methods for prefix management, collection enumeration,
# tag extraction, and cache clearing operations, ensuring consistent behavior
# across different cache backends such as
# memory, Redis, and SQLite.
module Documentrix::Documents::Cache::Common
  include Documentrix::Utils::Math
  include Documentrix::Utils::Digests
  include Enumerable

  # The initialize method sets up the Documentrix::Documents::Cache instance's
  # by setting its prefix attribute to the given value.
  #
  # @param [String] prefix the string to be used as the prefix for this cache
  def initialize(prefix:)
    self.prefix = prefix
  end

  attr_accessor :prefix # current prefix defined for the cache

  # Returns an array of collection names that match the given prefix.
  #
  # @param prefix [String] a string to search for in collection names
  # @return [Array<Symbol>] an array of matching collection names
  def collections(prefix)
    unique = Set.new
    full_each do |key, _|
      key =~ /\A#{prefix}(.+)-/ or next
      unique << $1
    end
    unique.map(&:to_sym)
  end

  # Returns a string representing the given `key` prefixed with the defined
  # prefix.
  #
  # @param key [String] the key to prefix
  # @param prefix [String] the prefix to use (defaults to the cache's prefix)
  # @return [String] the prefixed key
  def pre(key, prefix: @prefix)
    [ prefix, key ].join
  end

  # Returns a string with the prefix removed from the given `key`.
  #
  # @param key [String] the input string containing the prefix.
  # @param prefix [String] the prefix to use (defaults to the cache's prefix)
  # @return [String] the input string without the prefix.
  def unpre(key, prefix: @prefix)
    key.sub(/\A#{prefix}/, '')
  end

  # The find_records method finds records that match the given needle and
  # tags.
  #
  # @param needle [ Array ] an array containing the embedding vector
  # @param tags [ String, Array ] a string or array of strings representing the tags to search for
  # @param max_records [ Integer ] the maximum number of records to return
  # @param min_similarity [ Float ] the minimum similarity score required for a record to be returned (defaults to -1)
  #
  # @return [ Array<Documentrix::Documents::Record> ] an array containing the matching records
  def find_records(needle, tags: nil, max_records: nil, min_similarity: -1)
    tags    = Documentrix::Utils::Tags.new(Array(tags)).to_a
    records = self
    if tags.present?
      records = records.select { |_key, record| (tags & record.tags).size >= 1 }
    end

    needle_norm = norm(needle)
    records     = records.map do |key, record|
      record.key        = key
      record.similarity = cosine_similarity(
        a:      needle,
        b:      record.embedding,
        a_norm: needle_norm,
        b_norm: record.norm,
      )
      record
    end.sort_by(&:similarity).reverse.select { _1.similarity >= min_similarity }

    max_records ? records.take(max_records) : records
  end

  # Returns a set of unique tags found in the cache records.
  #
  # This method iterates through all records in the cache and collects unique
  # tags from each record's tags collection. It constructs a new
  # Documentrix::Utils::Tags object containing all the unique tags encountered.
  #
  # @return [Documentrix::Utils::Tags] a set of unique tags from all records in
  #   the cache
  def tags
    each_with_object(Documentrix::Utils::Tags.new) do |(_, record), t|
      record.tags.each do |tag|
        t.add(tag, source: record.source)
      end
    end
  end

  # The clear_for_tags method removes all records from the cache that have tags
  # matching any of the provided tags.
  #
  # @param tags [Array<String>] an array of tag names to filter records by
  #
  # @return [self] self
  def clear_for_tags(tags)
    each do |key, record|
      if (tags & record.tags.to_a).size >= 1
        delete(unpre(key))
      end
    end
    self
  end

  # Yields each unique, full source present in the cache records.
  #
  # @yield [source] the full source string
  # @return [Enumerator] an enumerator if no block is given, nil otherwise.
  def each_source(&block)
    block or return enum_for(__method__)
    seen = {}
    each do |_key, record|
      source = record.source.full? or next
      seen.key?(source) and next
      seen[source] = true
      block.(source)
    end
    nil
  end

  # The clear_by_source method removes all records from the cache that
  # have a source matching the given source.
  #
  # @param source [String] the source to filter records by
  # @param digest [String, nil] the SHA256 hexadecimal digest of the source.
  # @param operator [Symbol, String] the operator to compare the digest with ('=' or '!=')
  #
  # @return [self] self
  def clear_by_source(source, digest: nil, operator: ?=)
    operator = operator == '=' ? '==' : '!='

    each do |key, record|
      next unless record.source == source
      if digest
        should_delete = record.digest.send(operator, digest)
        delete(unpre(key)) if should_delete
      else
        delete(unpre(key))
      end
    end
    self
  end

  # Checks if any records associated with the given source exist in the cache.
  #
  # @param source [String] the source to check for existence
  # @param digest [String, nil] the SHA256 hexadecimal digest to compare against
  # @param operator [Symbol, String] the operator to compare the digest with ('=' or '!=')
  #
  # @return [Boolean] true if a matching record is found, false otherwise.
  def source_exist?(source, digest: nil, operator: ?=)
    operator = operator == '=' ? '==' : '!='

    each do |_, record|
      next unless record.source == source
      if digest
        if record.digest.send(operator, digest)
          return true
        end
      else
        return true
      end
    end
    false
  end

  # The clear method removes cached records based on the provided tags or
  # clears all records with the current prefix.
  #
  # When tags are provided, it removes only the records that have matching
  # tags. If no tags are provided, it removes all records that have keys
  # starting with the current prefix.
  #
  # @param tags [NilClass, Array<String>] an array of tag names to filter
  #   records by, or nil to clear all records
  #
  # @return [self] returns the cache instance for method chaining
  def clear(tags: nil)
    tags = Documentrix::Utils::Tags.new(tags).to_a
    if tags.present?
      clear_for_tags(tags)
    else
      clear_all_with_prefix
    end
    self
  end
end
