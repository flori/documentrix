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
end
