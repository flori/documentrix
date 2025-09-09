module Documentrix::Documents::Cache::Records
  class Record < JSON::GenericObject
    # The initialize method sets default values for the text and norm
    # attributes.
    #
    # @param [Hash] options A hash containing optional parameters.
    def initialize(options = {})
      super
      self.text ||= ''
      self.norm ||= 0.0
    end

    # The to_s method returns a string representation of the object.
    #
    # @return [String] A string containing the text and tags of the record,
    # along with its similarity score.
    def to_s
      my_tags = tags_set
      my_tags.empty? or my_tags = " #{my_tags}"
      "#<#{self.class} #{text.inspect}#{my_tags} #{similarity || 'n/a'}>"
    end

    # The tags_set method creates a new Documentrix::Utils::Tags object from
    # the tags and source of this instance.
    #
    # @return [ Documentrix::Utils::Tags ] a new Documentrix::Utils::Tags object
    def tags_set
      Documentrix::Utils::Tags.new(tags, source:)
    end

    # The == method compares this record with another one by comparing their
    # text fields.
    #
    # @param other [ Documentrix::Documents::Record ] the other record to compare with
    #
    # @return [ FalseClass, TrueClass ] true if both records have the same
    #         text, false otherwise.
    def ==(other)
      text == other.text
    end

    alias inspect to_s
  end

  module RedisFullEach
    # The full_each method iterates over all records in the cache and yields
    # them to the block.
    #
    # @yield [ key, value ] where key is the record's key and value is the record itself
    def full_each(&block)
      redis.scan_each(match: [ Documentrix::Documents, ?* ] * ?-) do |key|
        value = redis.get(key) or next
        value = JSON(value, object_class: Documentrix::Documents::Record)
        block.(key, value)
      end
    end
  end

  module FindRecords
    # The find_records method finds records that match the given needle and
    # tags.
    #
    # @param needle [ Array ] an array containing the embedding vector
    # @param tags [ String, Array ] a string or array of strings representing the tags to search for
    # @param max_records [ Integer ] the maximum number of records to return
    #
    # @yield [ record ]
    #
    # @return [ Array<Documentrix::Documents::Records> ] an array containing the matching records
    def find_records(needle, tags: nil, max_records: nil)
      tags    = Documentrix::Utils::Tags.new(Array(tags)).to_a
      records = self
      if tags.present?
        records = records.select { |_key, record| (tags & record.tags).size >= 1 }
      end
      needle_norm = norm(needle)
      records     = records.sort_by { |key, record|
        record.key        = key
        record.similarity = cosine_similarity(
          a: needle,
          b: record.embedding,
          a_norm: needle_norm,
          b_norm: record.norm,
        )
      }
      records.transpose.last&.reverse.to_a
    end
  end

  module Tags
    # The clear method removes all records that match the given tags from the
    # cache.
    #
    # @param tags [ Array<String> ] an array of tag names
    #
    # @example
    #   documents.clear(tags: %w[ foo bar ])
    #
    # @return [ self ]
    def clear(tags: nil)
      tags = Documentrix::Utils::Tags.new(tags).to_a
      if tags.present?
        if respond_to?(:clear_for_tags)
          clear_for_tags(tags)
        else
          each do |key, record|
            if (tags & record.tags.to_a).size >= 1
              delete(unpre(key))
            end
          end
        end
      else
        super()
      end
      self
    end

    # The tags method returns an array of unique tags from all records.
    #
    # @return [Documentrix::Utils::Tags] An instance of
    #         Documentrix::Utils::Tags containing the unique tags.
    def tags
      if defined? super
        super
      else
        each_with_object(Documentrix::Utils::Tags.new) do |(_, record), t|
          record.tags.each do |tag|
            t.add(tag, source: record.source)
          end
        end
      end
    end
  end
end
