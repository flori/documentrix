require 'numo/narray'
require 'digest'
require 'kramdown/ansi'

class Documentrix::Documents
end
# Module for managing document caches in Documentrix
#
# This module provides the foundational cache interface and implementations for
# storing and retrieving document embeddings and related metadata. It supports
# multiple cache backends including memory, Redis, and SQLite, enabling
# flexible storage options for vector databases.
#
# The cache system handles operations such as setting, retrieving, and deleting
# cached entries, as well as querying and filtering cached data based on tags
# and similarity searches. It includes common functionality for managing cache
# prefixes, enumerating collections, extracting tags, and clearing cache entries.
module Documentrix::Documents::Cache
end
require 'documentrix/documents/cache/records'
require 'documentrix/documents/cache/memory_cache'
require 'documentrix/documents/cache/redis_cache'
require 'documentrix/documents/cache/redis_backed_memory_cache'
require 'documentrix/documents/cache/sqlite_cache'

# Module for text splitting operations in Documentrix
#
# This module provides functionality for splitting text into smaller chunks
# using various strategies. It includes both simple character-based splitting
# and more sophisticated semantic splitting that considers the meaning
# and structure of the text when determining split points.
#
# The splitters are designed to work with the Documentrix::Documents class
# to prepare text data for embedding and storage in vector databases.
module Documentrix::Documents::Splitters
end
require 'documentrix/documents/splitters/character'
require 'documentrix/documents/splitters/semantic'

# Documentrix::Documents is a class that provides functionality for building
# and querying vector databases for natural language processing and large
# language model applications.
#
# It allows users to store and retrieve dense vector embeddings for text
# strings, supporting various cache backends including memory, Redis, and
# SQLite for efficient data management.
#
# The class handles the complete workflow of adding documents, computing their
# embeddings using a specified model, storing them in a cache, and performing
# similarity searches to find relevant documents based on query text.
#
# @example
#   documents = Documentrix::Documents.new(
#     ollama: ollama_client,
#     model: 'mxbai-embed-large',
#     collection: 'my-collection'
#   )
#   documents.add(['text1', 'text2'])
#   results = documents.find('search query')
class Documentrix::Documents
  include Kramdown::ANSI::Width
  include Documentrix::Documents::Cache

  # Shortcut for Documentrix::Documents::Cache::Records::Record
  Record = Class.new Documentrix::Documents::Cache::Records::Record

  # The initialize method sets up the Documentrix::Documents instance by
  # configuring its components.
  #
  # @param ollama [ Ollama::Client ] the client used for embedding
  # @param model [ String ] the name of the model to use for embeddings
  # @param model_options [ Hash ] optional parameters for the model
  # @param collection [ Symbol ] the default collection to use (defaults to :default)
  # @param embedding_length [ Integer ] the length of the embeddings (defaults to 1024)
  # @param cache [ Documentrix::Cache ] the cache to use for storing documents (defaults to MemoryCache)
  # @param database_filename [ String ] the filename of the SQLite database to use (defaults to ':memory:')
  # @param redis_url [ String ] the URL of the Redis server to use (defaults to nil)
  # @param debug [ FalseClass, TrueClass ] whether to enable debugging mode (defaults to false)
  def initialize(ollama:, model:, model_options: nil, collection: nil, embedding_length: 1_024, cache: MemoryCache, database_filename: nil, redis_url: nil, debug: false)
    collection ||= default_collection
    @ollama, @model, @model_options, @collection, @debug =
      ollama, model, model_options, collection.to_sym, debug
    database_filename ||= ':memory:'
    @cache = connect_cache(cache, redis_url, embedding_length, database_filename)
  end

  # The default_collection method returns the default collection name.
  #
  # @return [:default] The default collection name.
  def default_collection
    :default
  end

  attr_reader :ollama, :model, :collection, :cache

  # The collection= method sets the new collection for this documents instance.
  #
  # @param new_collection [ Symbol ] the name of the new collection
  def collection=(new_collection)
    @collection   = new_collection.to_sym
    @cache.prefix = prefix
  end

  # The prepare_texts method filters out existing texts from the input array
  # and returns the filtered array.
  #
  # @param texts [ Array ] an array of text strings or #read objects.
  #
  # @return [ Array ] the filtered array of text strings
  private def prepare_texts(texts)
    texts = Array(texts).map! { |i| i.respond_to?(:read) ? i.read : i.to_s }
    texts.reject! { |i| exist?(i) }
    texts.empty? and return
    if @debug
      puts Documentrix::Utils::ColorizeTexts.new(texts)
    end
    texts
  end


  # The  method adds new texts `texts` to the documents collection by
  # processing them through various stages. It first filters out existing texts
  # from the input array using the `prepare_texts` method, then fetches
  # embeddings for each text using the specified model and options. The fetched
  # embeddings are used to create a new record in the cache, which is
  # associated with the original text and tags (if any). The method processes
  # the texts in batches of size , displaying progress information
  # in the console. It also accepts an optional  string to associate
  # with the added texts and an array of  to attach to each record. Once
  # all texts have been processed, it returns the `Documentrix::Documents`
  # instance itself, allowing for method chaining.
  #
  # @param texts [Array] an array of input texts
  # @param batch_size [Integer] the number of texts to process in one batch
  # @param source [String] the source URL for the added texts
  # @param tags [Array] an array of tags associated with the added texts
  #
  # @example
  #   documents.add(%w[ foo bar ], batch_size: 23, source: 'https://example.com', tags: %w[tag1 tag2])
  #
  # @return [Documentrix::Documents] self
  def add(texts, batch_size: nil, source: nil, tags: [])
    texts = prepare_texts(texts) or return self
    tags = Documentrix::Utils::Tags.new(tags, source:)
    if source
      tags.add(File.basename(source).gsub(/\?.*/, ''), source:)
    end
    batches = texts.each_slice(batch_size || 10).
      with_infobar(
        label: "Add #{truncate(tags.to_s(link: false), percentage: 25)}",
        total: texts.size
      )
    batches.each do |batch|
      embeddings = fetch_embeddings(model:, options: @model_options, input: batch)
      batch.zip(embeddings) do |text, embedding|
        norm       = @cache.norm(embedding)
        self[text] = Record[text:, embedding:, norm:, source:, tags: tags.to_a]
      end
      infobar.progress by: batch.size
    end
    infobar.newline
    self
  end
  alias << add

  # The [] method retrieves the value associated with the given text  from the
  # cache.
  #
  # @param text [String] the text for which to retrieve the cached value
  #
  # @return [Object] the cached value, or nil if not found
  def [](text)
    @cache[key(text)]
  end

  # The []= method sets the value for a given text in the cache.
  #
  # @param text [ String ] the text to set
  # @param record [ Hash ] the value to store
  def []=(text, record)
    @cache[key(text)] = record
  end

  # The exist? method checks if the given text exists in the cache.
  #
  # @param text [ String ] the text to check for existence
  #
  # @return [ FalseClass, TrueClass ] true if the text exists, false otherwise.
  def exist?(text)
    @cache.key?(key(text))
  end

  # The delete method removes the specified text from the cache by calling the
  # delete method on the underlying cache object.
  #
  # @param text [ String ] the text for which to remove the value
  #
  # @return [ FalseClass, TrueClass ] true if the text was removed, false
  #         otherwise.
  def delete(text)
    @cache.delete(key(text))
  end

  # The size method returns the number of texts stored in the cache of this
  # Documentrix::Documents instance.
  #
  # @return [ Integer ] The total count of cached texts.
  def size
    @cache.size
  end

  # The clear method clears all texts from the cache or tags was given the ones
  # tagged with the .
  #
  # @param tags [ NilClass, Array<String> ] the tag name to filter by
  #
  # @return [ Documentrix::Documents ] self
  def clear(tags: nil)
    @cache.clear(tags:)
    self
  end

  # The find method searches for strings within the cache by computing their
  # similarity scores.
  #
  # @param string [String] the input string
  # @param tags [Array<String>] an array of tags to filter results by (optional)
  # @param prompt [String] a prompt to use when searching for similar strings (optional)
  # @param max_records [Integer] the maximum number of records to return (optional)
  #
  # @example
  #   documents.find("foo")
  #
  # @return [Array<Documentrix::Documents::Record>]
  def find(string, tags: nil, prompt: nil, max_records: nil)
    needle = convert_to_vector(string, prompt:)
    @cache.find_records(needle, tags:, max_records: nil)
  end

  # The  method filters the records returned by find based on text
  # size and count.
  #
  # @param string [String] the search query
  # @param text_size [Integer] the maximum allowed text size to return
  # @param text_count [Integer] the maximum number of texts to return
  #
  # @example
  #   documents.find_where('foo', text_size: 3, text_count: 1)
  # @return [Array<Documentrix::Documents::Record>] the filtered records
  def find_where(string, text_size: nil, text_count: nil, **opts)
    if text_count
      opts[:max_records] =  text_count
    end
    records = find(string, **opts)
    size, count = 0, 0
    records.take_while do |record|
      if text_size and (size += record.text.size) > text_size
        next false
      end
      if text_count and (count += 1) > text_count
        next false
      end
      true
    end
  end

  # The collections method returns an array of unique collection names
  #
  # @return [Array] An array of unique collection names
  def collections
    ([ default_collection ] + @cache.collections('%s-' % class_prefix)).uniq
  end

  # The tags method returns an array of unique tags from the cache.
  #
  # @return [Documentrix::Utils::Tags] A set of unique tags
  def tags
    @cache.tags
  end

  private

  # The connect_cache method initializes and returns an instance of the
  # specified cache class.
  #
  # @param cache_class [Class] the class of the cache to be instantiated
  # @param redis_url [String] the URL of the Redis server
  # @param embedding_length [Integer] the length of the embeddings used in the cache
  # @param database_filename [String] the filename of the SQLite database file
  #
  # @return [CacheInstance] an instance of the specified cache class
  def connect_cache(cache_class, redis_url, embedding_length, database_filename)
    cache = nil
    if (cache_class.instance_method(:redis) rescue nil)
      begin
        cache = cache_class.new(prefix:, url: redis_url, object_class: Record)
        cache.size
      rescue Redis::CannotConnectError
        STDERR.puts(
          "Cannot connect to redis URL #{redis_url.inspect}, "\
          "falling back to MemoryCache."
        )
      end
    elsif cache_class == SQLiteCache
      cache = cache_class.new(
        prefix:,
        embedding_length:,
        filename: database_filename,
        debug: @debug
      )
    end
  ensure
    cache ||= MemoryCache.new(prefix:,)
    return cache
  end

  # The convert_to_vector method converts the input into a vector by fetching
  # embeddings from the model and then converting it using the cache's
  # convert_to_vector method.
  #
  # @param input [String] the string to be converted
  # @param prompt [String, nil] an optional prompt to be used in the conversion process
  #
  # @return [Array] the converted vector
  def convert_to_vector(input, prompt: nil)
    if prompt
      input = prompt % input
    end
    input.is_a?(String) and input = fetch_embeddings(model:, input:).first
    @cache.convert_to_vector(input)
  end

  # The fetch_embeddings method retrieves the embeddings for a given input
  # using the specified model and options.
  #
  # @param model [ String ] the name of the model used for embedding
  # @param input [ Array<String> ] the text(s) to be embedded
  # @param options [ Hash ] optional parameters for the embedding process
  #
  # @return [ Array<Array<Float>> ] an array containing the embeddings for each input string
  def fetch_embeddings(model:, input:, options: nil)
    @ollama.embed(model:, input:, options:).embeddings
  end

  def class_prefix
    'Documents'
  end

  # The prefix method returns a string that is used as the prefix for keys in
  # the cache of the currently configured collection.
  #
  # @return [ String ] The prefix string
  def prefix
    '%s-%s-' % [ class_prefix, @collection ]
  end

  # The key method generates a SHA256 hash for the given input string.
  #
  # @param input [String] the input string to be hashed
  #
  # @return [String] the SHA256 hash of the input string
  def key(input)
    Digest::SHA256.hexdigest(input)
  end
end
