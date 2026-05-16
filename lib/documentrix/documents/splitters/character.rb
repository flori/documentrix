module Documentrix::Documents::Splitters
  # The Character class provides basic text splitting based on a single
  # separator and bundles the resulting segments into chunks of a maximum size.
  #
  # It allows for the preservation of separators and uses a combining string
  # to join segments back together into chunks.
  class Character
    include Documentrix::Documents::Splitters::Common

    # The default regex used to identify paragraph boundaries.
    # It matches two or more consecutive newline characters (CRLF or LF).
    #
    # @return [Regexp]
    DEFAULT_SEPARATOR = /(?:\r?\n){2,}/

    # Initializes a new Character splitter.
    #
    # @param separator [Regexp] the regex used to split the text (defaults to DEFAULT_SEPARATOR)
    # @param include_separator [Boolean] whether to include the separator in the resulting chunks (defaults to false)
    # @param combining_string [String] the string used to join segments into chunks (defaults to "\n\n")
    # @param chunk_size [Integer] the maximum size of each resulting chunk (defaults to 4096)
    # @param force [Boolean] whether to force-split the final chunk if it exceeds `chunk_size` (defaults to false)
    def initialize(separator: DEFAULT_SEPARATOR, include_separator: false, combining_string: "\n\n", chunk_size: 4096, force: false)
      @separator, @include_separator, @combining_string, @chunk_size, @force =
        separator, include_separator, combining_string, chunk_size, force
      if include_separator
        @separator = Regexp.new("(#@separator)")
      end
    end

    # Splits the given text into chunks based on the configured separator and
    # size limit.
    #
    # @param text [String] the text to be split
    # @return [Array<String>] an array of text chunks
    def split(text)
      texts = []
      text.split(@separator) do |t|
        if @include_separator && t =~ @separator
          texts.last&.concat t
        else
          texts.push(t)
        end
      end
      result = []
      current_text = +''
      texts.each do |t|
        if current_text.size + t.size < @chunk_size
          current_text << t << @combining_string
        else
          current_text.empty? or result << current_text
          current_text = t
        end
      end
      result.concat force_split(current_text)
      result
    end
  end

  # The RecursiveCharacter class implements a hierarchical splitting strategy.
  #
  # It attempts to split text using a priority list of separators. If a
  # resulting chunk is still larger than the specified chunk_size, it
  # recursively applies the next separator in the list until the size limit is
  # met or all separators have been exhausted.
  class RecursiveCharacter
    include Documentrix::Documents::Splitters::Common

    # The default priority list of regexes used for recursive splitting.
    # The strategy is to split by the coarsest grain first (paragraphs)
    # and move toward the finest grain (individual characters) as needed.
    #
    # Order: Paragraphs -> Newlines -> Word Boundaries -> Characters
    #
    # @return [Array<Regexp>]
    DEFAULT_SEPARATORS = [
      /(?:\r?\n){2,}/,
      /\r?\n/,
      /\b/,
      //,
    ].freeze

    # Initializes a new RecursiveCharacter splitter.
    #
    # @param separators [Array<Regexp>] a priority list of regexes to use for splitting (defaults to DEFAULT_SEPARATORS)
    # @param include_separator [Boolean] whether to include the separator in the resulting chunks (defaults to false)
    # @param combining_string [String] the string used to join segments into chunks (defaults to "\n\n")
    # @param chunk_size [Integer] the maximum size of each resulting chunk (defaults to 4096)
    # @raise [ArgumentError] if the separators array is empty
    def initialize(separators: DEFAULT_SEPARATORS, include_separator: false, combining_string: "\n\n", chunk_size: 4096)
      separators.empty? and
        raise ArgumentError, "non-empty array of separators required"
      @separators, @include_separator, @combining_string, @chunk_size =
        separators, include_separator, combining_string, chunk_size
      @force = separators.last == //
    end

    # Recursively splits the given text into chunks using the list of
    # separators.
    #
    # @param text [String] the text to be split
    # @param separators [Array<Regexp>] the list of separators to use (defaults to @separators)
    # @return [Array<String>] an array of text chunks
    def split(text, separators: @separators)
      separators.empty? and return [ text ]
      separators = separators.dup
      separator = separators.shift
      texts = Character.new(
        separator:,
        include_separator: @include_separator,
        combining_string: @combining_string,
        chunk_size: @chunk_size
      ).split(text)
      texts.count == 0 and return [ text ]
      texts.inject([]) do |r, t|
        if t.size > @chunk_size
          r.concat(split(t, separators:))
        else
          r.concat([ t ])
        end
      end
    end
  end
end
