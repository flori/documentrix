require 'documentrix/documents/cache/common'
require 'sqlite3'
require 'sqlite_vec'
require 'digest/md5'

class Documentrix::Documents::Cache::SQLiteCache
  include Documentrix::Documents::Cache::Common

  # The initialize method sets up the cache by calling super and setting
  # various instance variables.
  #
  # @param prefix [ String ] the prefix for keys
  # @param embedding_length [ Integer ] the length of the embeddings vector
  # @param filename [ String ] the name of the SQLite database file or ':memory:' for in-memory.
  # @param debug [ FalseClass, TrueClass ] whether to enable debugging
  #
  # @return [ void ]
  def initialize(prefix:, embedding_length: 1_024, filename: ':memory:', debug: false)
    super(prefix:)
    @embedding_length = embedding_length
    @filename         = filename
    @debug            = debug
    setup_database(filename)
  end

  attr_reader :filename # filename for the database, `:memory:` is in memory

  attr_reader :embedding_length # length of the embeddings vector

  # The [](key) method retrieves the value associated with the given key from
  # the cache.
  #
  # @param [String] key The key for which to retrieve the value.
  #
  # @return [Documentrix::Documents::Record, NilClass] The value associated
  #         with the key, or nil if it does not exist in the cache.
  def [](key)
    result = execute(
      %{
        SELECT records.key, records.text, records.norm, records.source,
          records.tags, embeddings.embedding
        FROM records
        INNER JOIN embeddings ON records.embedding_id = embeddings.rowid
        WHERE records.key = ?
      },
      pre(key)
    )&.first or return
    key, text, norm, source, tags, embedding = *result
    embedding = embedding.unpack("f*")
    tags      = Documentrix::Utils::Tags.new(JSON(tags.to_s).to_a, source:)
    convert_value_to_record(key:, text:, norm:, source:, tags:, embedding:)
  end

  # The []= method sets the value for a given key by inserting it into the
  # database.
  #
  # @param [String] key the key to set
  # @param [Hash, Documentrix::Documents::Record] value the hash or record
  #        containing the text, embedding, and other metadata
  def []=(key, value)
    value = convert_value_to_record(value)
    embedding = value.embedding.pack("f*")
    execute(%{BEGIN})
    execute(%{INSERT INTO embeddings(embedding) VALUES(?)}, [ embedding ])
    embedding_id, = execute(%{ SELECT last_insert_rowid() }).flatten
    execute(%{
      INSERT INTO records(key,text,embedding_id,norm,source,tags)
      VALUES(?,?,?,?,?,?)
    }, [ pre(key), value.text, embedding_id, value.norm, value.source, JSON(value.tags) ])
    execute(%{COMMIT})
  end

  # The key? method checks if the given key exists in the cache by executing a
  # SQL query.
  #
  # @param [String] key the key to check for existence
  #
  # @return [FalseClass, TrueClass] true if the key exists, false otherwise
  def key?(key)
    execute(
      %{ SELECT count(records.key) FROM records WHERE records.key = ? },
      pre(key)
    ).flatten.first == 1
  end

  # The delete method removes a key from the cache by executing a SQL query.
  #
  # @param key [ String ] the key to be deleted
  #
  # @return [ NilClass ]
  def delete(key)
    result = key?(key)
    execute(
      %{ DELETE FROM records WHERE records.key = ? },
      pre(key)
    )
    result
  end

  # The tags method returns an array of unique tags from the database.
  #
  # @return [Documentrix::Utils::Tags] An instance of Documentrix::Utils::Tags
  #         containing all unique tags found in the database.
  def tags
    result = Documentrix::Utils::Tags.new
    execute(%{
        SELECT DISTINCT(tags) FROM records WHERE key LIKE ?
      }, [ "#@prefix%" ]
    ).flatten.each do
      JSON(_1).each { |t| result.add(t) }
    end
    result
  end

  # The size method returns the total number of records stored in the cache,
  # that is the ones with prefix `prefix`.
  #
  # @return [ Integer ] the count of records
  def size
    execute(%{SELECT COUNT(*) FROM records WHERE key LIKE ?}, [ "#@prefix%" ]).flatten.first
  end

  # The clear_for_tags method clears the cache for specific tags by deleting
  # records that match those tags and have the prefix `prefix`.
  #
  # @param tags [Array<String>, NilClass] An array of tag names to clear from
  #        the cache or nil for all records
  #
  # @return [Documentrix::Documents::Cache::SQLiteCache] The SQLiteCache instance
  #         after clearing the specified tags.
  def clear_for_tags(tags = nil)
    tags = Documentrix::Utils::Tags.new(tags).to_a
    if tags.present?
      records = find_records_for_tags(tags)
      keys = '(%s)' % records.transpose.first.map { "'%s'" % quote(_1) }.join(?,)
      execute(%{DELETE FROM records WHERE key IN #{keys}})
    else
      clear_all_with_prefix
    end
    self
  end

  # The clear_all_with_prefix method deletes all records for prefix `prefix`
  # from the cache by executing a SQL query.
  #
  # @return [ Documentrix::Documents::RedisBackedMemoryCache ] self
  def clear_all_with_prefix
    execute(%{DELETE FROM records WHERE key LIKE ?}, [ "#@prefix%" ])
    self
  end

  # The each method iterates over records matching the given prefix and yields
  # them to the block.
  #
  # @param prefix [ String ] the prefix to match
  # @yield [ key, value ] where key is the record's key and value is the record itself
  #
  # @example
  #   cache.each do |key, value|
  #     puts "#{key}: #{value}"
  #   end
  def each(prefix: "#@prefix%", &block)
    execute(%{
      SELECT records.key, records.text, records.norm, records.source,
        records.tags, embeddings.embedding
      FROM records
      INNER JOIN embeddings ON records.embedding_id = embeddings.rowid
      WHERE records.key LIKE ?
    }, [ prefix ]).each do |key, text, norm, source, tags, embedding|
      embedding = embedding.unpack("f*")
      tags      = Documentrix::Utils::Tags.new(JSON(tags.to_s).to_a, source:)
      value     = convert_value_to_record(key:, text:, norm:, source:, tags:, embedding:)
      block.(key, value)
    end
    self
  end

  # The full_each method iterates over all keys and values in the cache,
  # regardless of their prefix.
  #
  # @yield [ key, value ]
  #
  # @return [ Documentrix::Documents::Cache::SQLiteCache ] self
  def full_each(&block)
    each(prefix: ?%, &block)
  end

  # The convert_to_vector method returns the input vector itself, because
  # conversion isn't necessary for this cache class.
  #
  # @param vector [ Array ] the input vector
  #
  # @return [ Array ] the (not) converted vector
  def convert_to_vector(vector)
    vector
  end

  # The find_records_for_tags method filters records based on the provided tags.
  #
  # @param tags [ Array ] an array of tag names
  #
  # @return [ Array ] an array of filtered records
  def find_records_for_tags(tags)
    if tags.present?
      tags_filter = Documentrix::Utils::Tags.new(tags).to_a
      unless tags_filter.empty?
        tags_where = ' AND (%s)' % tags_filter.map {
          'tags LIKE "%%%s%%"' % quote(_1)
        }.join(' OR ')
      end
    end
    records = execute(%{
      SELECT key, tags, embedding_id
      FROM records
      WHERE key LIKE ?#{tags_where}
    }, [ "#@prefix%" ])
    if tags_filter
      records = records.select { |key, tags, embedding_id|
        (tags_filter & JSON(tags.to_s).to_a).size >= 1
      }
    end
    records
  end

  # The find_records method finds records that match the given needle and tags.
  #
  # @param needle [ Array ] the embedding vector
  # @param tags [ Array ] the list of tags to filter by (optional)
  # @param max_records [ Integer ] the maximum number of records to return (optional)
  #
  # @yield [ key, value ]
  #
  # @raise [ ArgumentError ] if needle size does not match embedding length
  #
  # @example
  #   documents.find_records([ 0.1 ] * 1_024, tags: %w[ test ])
  #
  # @return [ Array<Documentrix::Documents::Record> ] the list of matching records
  def find_records(needle, tags: nil, max_records: nil)
    needle.size != @embedding_length and
      raise ArgumentError, "needle embedding length != %s" % @embedding_length
    needle_binary = needle.pack("f*")
    max_records   = [ max_records, size, 4_096 ].compact.min
    records = find_records_for_tags(tags)
    rowids_where = '(%s)' % records.transpose.last&.join(?,)
    execute(%{
      SELECT records.key, records.text, records.norm, records.source,
        records.tags, embeddings.embedding
      FROM records
      INNER JOIN embeddings ON records.embedding_id = embeddings.rowid
      WHERE embeddings.rowid IN #{rowids_where}
        AND embeddings.embedding MATCH ? AND embeddings.k = ?
    }, [ needle_binary, max_records ]).map do |key, text, norm, source, tags, embedding|
      key       = unpre(key)
      embedding = embedding.unpack("f*")
      tags      = Documentrix::Utils::Tags.new(JSON(tags.to_s).to_a, source:)
      convert_value_to_record(key:, text:, norm:, source:, tags:, embedding:)
    end
  end

  private

  # The execute method executes an SQL query on the database by calling the
  # \@database.execute method.
  #
  # @param [Array] a the arguments to be passed to the @database.execute method
  #
  # @return [Result] the result of the executed query
  def execute(*a)
    if @debug
      e = a[0].gsub(/^\s*\n/, '')
      e = e.gsub(/\A\s+/, '')
      n = $&.to_s.size
      e = e.gsub(/^\s{0,#{n}}/, '')
      e = e.chomp
      STDERR.puts("EXPLANATION:\n%s\n%s" % [
        e,
        @database.execute("EXPLAIN #{e}", *a[1..-1]).pretty_inspect
      ])
    end
    @database.execute(*a)
  end

  # The quote method returns the quoted string as per
  # SQLite3::Database.quote(string).
  #
  # @param string [String] the input string
  #
  # @return [String] the quoted string
  def quote(string)
    SQLite3::Database.quote(string)
  end

  # The setup_database method initializes the SQLite database by creating
  # tables and loading extensions.
  #
  # @param filename [ String ] the name of the SQLite database file
  #
  # @return [ nil ]
  def setup_database(filename)
    @database = SQLite3::Database.new(filename)
    @database.enable_load_extension(true)
    SqliteVec.load(@database)
    @database.enable_load_extension(false)
    execute %{
      CREATE VIRTUAL TABLE IF NOT EXISTS embeddings USING vec0(
        embedding float[#@embedding_length]
      )
    }
    execute %{
      CREATE TABLE IF NOT EXISTS records (
        key          text NOT NULL PRIMARY KEY ON CONFLICT REPLACE,
        text         text NOT NULL DEFAULT '',
        embedding_id integer,
        norm         float NOT NULL DEFAULT 0.0,
        source       text,
        tags         json NOT NULL DEFAULT [],
        FOREIGN KEY(embedding_id) REFERENCES embeddings(id) ON DELETE CASCADE
      )
    }
    nil
  end

  # The convert_value_to_record method converts the given value into a
  # Documentrix::Documents::Record object.
  #
  # @param value [ Documentrix::Documents::Record, Hash ] the value to be converted
  #
  # @return [ Documentrix::Documents::Record ] the converted record object
  def convert_value_to_record(value)
    value.is_a?(Documentrix::Documents::Record) and return value
    Documentrix::Documents::Record[value.to_hash]
  end
end
