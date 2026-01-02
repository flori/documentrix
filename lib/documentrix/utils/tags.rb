require 'term/ansicolor'

# A collection of tags with optional source tracking and formatting
# capabilities.
#
# The Tags class manages a collection of unique tags, ensuring no duplicates while maintaining sorted order.
# Each tag can optionally be associated with a source URL for tracking origins.
# The class provides methods for adding, iterating, and formatting tags for display.
#
# @example
#   tags = Documentrix::Utils::Tags.new(%w[ foo bar ])
#   tags.add('baz')
#   tags.to_s # => "bar baz foo"
class Documentrix::Utils::Tags
  # Matches tags with optional leading # characters and at least one non-space
  # character by default:
  DEFAULT_VALID_TAG = /\A#*(\S+)/

  # A tag string that includes optional source tracking functionality.
  #
  # The Tag class extends String and adds the ability to track the source URL
  # where the tag originated. It provides methods for formatting the tag string
  # for output, including the option to include a hyperlink to the source.
  #
  # @example
  #   tag = Documentrix::Utils::Tags::Tag.new('example')
  #   tag.source = 'https://example.com'
  #   tag.to_s # => "\e]8;;https://example.com\e\\\\#example\e]8;;\e\\\\"
  class Tag < String
    include Term::ANSIColor

    # The initialize method sets up the Tag object by calling its superclass's
    # constructor and setting the source attribute.
    #
    # @param tag [String] the string representation of the tag
    # @param source [String, nil] the source URL for the tag (default: nil)
    def initialize(tag, valid_tag: DEFAULT_VALID_TAG, source: nil)
      super(tag.to_s[valid_tag, 1])
      self.source = source
    end

    attr_accessor :source # the source URL for the tag

    attr_reader :valid_tag # the regular expression capturing a valid tag's content

    # The to_s method formats the tag string for output, including source URL
    # if requested.
    #
    # @param link [FalseClass, TrueClass] whether to include source URL (default: true)
    #
    # @return [String] the formatted tag string
    def to_s(link: true)
      tag_string = start_with?(?#) ? super() : ?# + super()
      my_source  = source
      if link && my_source
        unless my_source =~ %r(\A(https?|file)://)
          my_source = 'file://%s' % File.expand_path(my_source)
        end
        hyperlink(my_source) { tag_string }
      else
        tag_string
      end
    end
  end

  # The initialize method sets up the Documentrix::Utils::Tags object by
  # processing an array of tags and adding them to the internal set.
  #
  # @param tags [Array<String>] the input array of strings representing tags
  # @param source [String, nil] the optional source URL for the tags (default: nil)
  #
  # @example
  #   Documentrix::Utils::Tags.new(%w[ foo bar ])
  #
  # @return [Documentrix::Utils::Tags] an instance of Documentrix::Utils::Tags
  def initialize(tags = [], valid_tag: DEFAULT_VALID_TAG, source: nil)
    tags       = Array(tags)
    @valid_tag = valid_tag
    @set       = []
    tags.each { |tag| add(tag, source:) }
  end

  attr_reader :valid_tag # the regular expression capturing a valid tag's content

  # The add method adds a tag to the collection, ensuring uniqueness and
  # maintaining sorted order.
  #
  # If the tag is not already a Tag instance, it creates one using the provided
  # source. The method uses binary search to find the correct insertion point
  # to maintain the sorted order.
  # Duplicate tags are not added, and the method returns self to allow for
  # method chaining.
  #
  # @param tag [ String, Documentrix::Utils::Tags::Tag ] the tag to be added
  # @param source [ String, nil ] the source URL associated with the tag (optional)
  #
  # @return [ Documentrix::Utils::Tags ] self
  def add(tag, source: nil)
    unless tag.is_a?(Tag)
      tag = Tag.new(tag, valid_tag:, source:)
    end
    index = @set.bsearch_index { _1 >= tag }
    if index == nil
      @set.push(tag)
    elsif @set.at(index) != tag
      @set.insert(index, tag)
    end
    self
  end

  # The empty? method checks if the Tags instance's set is empty.
  #
  # @return [TrueClass] true if the set is empty, false otherwise
  def empty?
    @set.empty?
  end

  # The size method returns the number of elements in the set.
  #
  # @return [Integer] The size of the set.
  def size
    @set.size
  end


  # The clear method resets the Documentrix::Utils::Tags instance's set by
  # calling its clear method.
  #
  # @return [Documentrix::Utils::Tags] self
  def clear
    @set.clear
    self
  end

  # The each method iterates over this Tags instance's set and yields each tags
  # to the given block.
  #
  # @yield [element] Each tag in the set
  #
  # @return [Documentrix::Utils::Tags] self
  def each(&block)
    @set.each(&block)
    self
  end
  include Enumerable

  # The to_s method formats the tags string for output, including source URL if requested.
  #
  # @param link [FalseClass, TrueClass] whether to include source URL (default: true)
  #
  # @return [Array<String>] the array of formatted tags strings
  def to_s(link: true)
    @set.map { |tag| tag.to_s(link:) } * ' '
  end
end
