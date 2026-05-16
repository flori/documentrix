# A shared utility module for text splitters that provides consistent
# handling of chunk size constraints.
#
# This module is intended to be included in splitter classes that
# implement a maximum chunk size limit. It expects the including class
# to provide the following attributes:
# - `force` [Boolean]: Whether to hard-split chunks that exceed the limit.
# - `chunk_size` [Integer]: The maximum allowed size for a single chunk.
module Documentrix::Documents::Splitters::Common
  private

  # Whether to force-split chunks that exceed the chunk size limit.
  # @return [Boolean]
  attr_reader :force

  # The maximum allowed size for a single chunk.
  # @return [Integer]
  attr_reader :chunk_size

  # Ensures text respects the chunk size limit if force splitting is enabled.
  #
  # If the `force` attribute is true and the provided text exceeds the
  # `chunk_size`, the text is hard-split into fixed-size chunks using a
  # regular expression. If `force` is false or the text is within the
  # limit, the text is returned wrapped in a single-element array to
  # maintain return-type consistency (Array<String>).
  #
  # @param text [String, nil] the text to potentially split
  # @return [Array<String>] the resulting chunk(s), or an empty array if text is nil/empty
  def force_split(text)
    text&.empty? and return []
    if force && text.size > chunk_size
      text.scan(/.{1,#{chunk_size}}/)
    else
      Array(text)
    end
  end
end
