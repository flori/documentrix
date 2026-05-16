module Documentrix::Documents::Splitters
  # Semantic splitter that divides text based on thematic changes in meaning.
  #
  # It works by splitting text into sentences, computing embeddings for each,
  # and then calculating the cosine distance between adjacent sentences.
  # Where the distance exceeds a calculated threshold (the "breakpoint"),
  # a semantic boundary is identified.
  #
  # @example
  #   splitter = Documentrix::Documents::Splitters::Semantic.new(
  #     ollama: ollama_client,
  #     model: 'mxbai-embed-large'
  #   )
  #   chunks = splitter.split(text, breakpoint: :percentile, percentile: 90)
  class Semantic
    include Documentrix::Documents::Splitters::Common
    include Documentrix::Utils::Math

    # The default regex used to identify sentence boundaries for semantic
    # splitting. It matches a sentence-ending punctuation mark (., !, ?)
    # followed by optional whitespace at a word boundary or the end of the
    # string.
    #
    # @return [Regexp]
    DEFAULT_SEPARATOR = /[.!?,;]\s*(?:\b|\z)/

    # Initializes a new Semantic splitter.
    #
    # @param ollama [Ollama::Client] the client used for generating embeddings
    # @param model [String] the embedding model name
    # @param model_options [Hash, nil] optional parameters passed to the embedding model
    # @param separator [Regexp] the regex used to identify sentence boundaries
    # @param chunk_size [Integer] the maximum character length of a resulting chunk
    # @param force [Boolean] whether to force split chunks that exceed chunk_size (defaults to false)
    def initialize(ollama:, model:, model_options: nil, separator: DEFAULT_SEPARATOR, chunk_size: 4096, force: false)
      @ollama, @model, @model_options, @separator, @chunk_size, @force =
        ollama, model, model_options, separator, chunk_size, force
    end

    # Splits the given text into semantic chunks.
    #
    # The method first decomposes the text into sentences, then identifies gaps
    # in semantic similarity. It then groups these sentences into chunks that
    # respect both the semantic boundaries and the maximum chunk size.
    #
    # @param text [String] the text to be split
    # @param batch_size [Integer] the number of sentences to embed in a single API call
    # @param breakpoint [Symbol] the method used to determine the distance threshold
    #   * :percentile (default) - uses the N-th percentile of distances
    #   * :standard_deviation - uses mean + (std_dev * multiplier)
    #   * :interquartile - uses mean + (iqr * multiplier)
    # @param opts [Hash] additional options for the splitting process:
    #   * :include_separator [Boolean] whether to keep the sentence separator in the result
    #   * :percentile [Integer] the percentile to use if breakpoint is :percentile (default: 95)
    #   * :percentage [Integer] the multiplier percentage for :standard_deviation or :interquartile (default: 100)
    #
    # @return [Array<String>] an array of semantically grouped text chunks
    def split(text, batch_size: 100, breakpoint: :percentile, **opts)
      sentences  = Documentrix::Documents::Splitters::Character.new(
        separator: @separator,
        include_separator: opts.fetch(:include_separator, true),
        chunk_size: 1,
      ).split(text)
      embeddings = sentences.with_infobar(label: 'Split').each_slice(batch_size).inject([]) do |e, batch|
        e.concat sentence_embeddings(batch)
        infobar.progress by: batch.size
        e
      end
      infobar.newline
      embeddings.size < 2 and return sentences
      distances = embeddings.each_cons(2).map do |a, b|
        1.0 - cosine_similarity(a:, b:)
      end
      max_distance = calculate_breakpoint_threshold(breakpoint, distances, **opts)
      gaps = distances.each_with_index.select do |d, i|
        d > max_distance
      end.transpose.last
      gaps or return sentences
      if gaps.last < distances.size
        gaps << distances.size
      end
      if gaps.last < sentences.size - 1
        gaps << sentences.size - 1
      end
      result = []
      sg = 0
      current_text = +''
      gaps.each do |g|
        sg.upto(g) do |i|
          sentence = sentences[i]
          if current_text.size + sentence.size < @chunk_size
            current_text += sentence
          else
            result.concat(force_split(current_text))
            current_text = sentence
          end
        end
        if current_text.present?
          result.concat(force_split(current_text))
          current_text = +''
        end
        sg = g.succ
      end
      result.concat(force_split(current_text))
      result
    end

    private

    # Calculates the distance threshold used to identify semantic boundaries.
    #
    # @param breakpoint_method [Symbol] the method to use (:percentile, :standard_deviation, :interquartile)
    # @param distances [Array<Float>] the cosine distances between adjacent sentences
    # @param opts [Hash] options specific to the chosen method (e.g., :percentile, :percentage)
    #
    # @return [Float] the distance threshold
    # @raise [ArgumentError] if an unsupported breakpoint_method is provided
    def calculate_breakpoint_threshold(breakpoint_method, distances, **opts)
      sequence = MoreMath::Sequence.new(distances)
      case breakpoint_method
      when :percentile
        percentile = opts.fetch(:percentile, 95)
        sequence.percentile(percentile)
      when :standard_deviation
        percentage = opts.fetch(:percentage, 100)
        (
          sequence.mean + sequence.standard_deviation * (percentage / 100.0)
        ).clamp(0, sequence.max)
      when :interquartile
        percentage = opts.fetch(:percentage, 100)
        iqr = sequence.interquartile_range
        max = sequence.max
        (sequence.mean + iqr * (percentage / 100.0)).clamp(0, max)
      else
        raise ArgumentError, "invalid breakpoint method #{breakpoint_method}"
      end
    end

    # Fetches embeddings for a batch of sentences and converts them to
    # Numo::NArray.
    #
    # @param input [Array<String>] the batch of sentences to embed
    # @return [Array<Numo::NArray>] an array of embeddings as Numo arrays
    def sentence_embeddings(input)
      @ollama.embed(model: @model, input:, options: @model_options).embeddings.map! {
        Numo::NArray[*_1]
      }
    end
  end
end
