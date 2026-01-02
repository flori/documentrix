# Module for cache record definitions used in Documentrix document caching.
#
# This module provides the Record class and RedisFullEach module for managing
# cached document embeddings and their associated metadata in the Documentrix
# library's caching system.
module Documentrix::Documents::Cache::Records
  # A record class for caching document embeddings and their associated
  # metadata.
  #
  # This class extends JSON::GenericObject and is used to represent cached
  # document entries in the Documentrix library. It stores text content,
  # embedding vectors, normalization values, source information, and tags
  # associated with each document record. The class provides methods for string
  # representation, tag handling, and equality comparison based on text
  # content.
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

  # Module for providing full iteration capability over Redis cache entries
  #
  # This module extends cache implementations to support iterating over all
  # entries in a Redis cache, regardless of prefix, by scanning all keys
  # matching a specific pattern and retrieving their values.
  #
  # @api private
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
