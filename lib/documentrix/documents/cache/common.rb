module Documentrix::Documents::Cache::Common
  include Documentrix::Utils::Math

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
  # @param key [String] the key to join with the prefix
  # @return [String] the joined string of prefix and key
  def pre(key)
    [ @prefix, key ].join
  end

  # Returns a string with the prefix removed from the given `key`.
  #
  # @param key [String] the input string containing the prefix.
  # @return [String] the input string without the prefix.
  def unpre(key)
    key.sub(/\A#@prefix/, '')
  end
end
