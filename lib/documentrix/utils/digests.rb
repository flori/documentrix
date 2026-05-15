require 'digest'
require 'uri'

# Module for computing cryptographic digests used for tracking content changes.
module Documentrix::Utils::Digests
  private

  @@file_digest_cache = {}

  # Computes the SHA256 hexadecimal digest of the given text.
  #
  # @param text [String] the text to be hashed
  # @return [String] the SHA256 hexadecimal digest
  def compute_digest(text)
    Digest::SHA256.hexdigest(text)
  end

  # Stores a computed digest in the internal cache, keyed by the filename
  # and the file's modification time.
  #
  # @param filename [String] the path to the file
  # @param stat [File::Stat] the status information of the file
  # @param digest [String] the SHA256 digest to store
  # @return [void]
  def file_digest_store(filename, stat, digest)
    @@file_digest_cache[[filename, stat.mtime]] = digest
  end

  # Checks if a valid digest exists in the internal cache for the given
  # filename and modification time.
  #
  # @param filename [String] the path to the file
  # @param stat [File::Stat] the status information of the file
  # @return [String, nil] the cached digest if found, nil otherwise
  def file_digest_cached?(filename, stat)
    @@file_digest_cache.fetch([filename, stat.mtime], nil)
  end

  # Clears the internal file digest cache.
  #
  # This removes all stored digests and their associated modification times,
  # forcing subsequent calls to #compute_file_digest to re-read files from
  # disk.
  def file_digest_cache_clear
    @@file_digest_cache&.clear
  end

  # Computes the SHA256 hexadecimal digest of a local file's content.
  #
  # This method first verifies that the provided filename is not an absolute
  # URL and that the file actually exists on the filesystem before reading
  # and hashing its content. It uses an internal cache to avoid re-reading
  # the file if the modification time has not changed.
  #
  # @param filename [String, #to_s] the path to the local file
  # @return [String, nil] the SHA256 hexadecimal digest if the file is a
  #   valid local file and exists, nil otherwise.
  def compute_file_digest(filename)
    filename = filename.to_s
    case
    when !filename.present?
      nil
    when (URI::PARSER.parse(filename).absolute? rescue nil)
      nil
    else
      stat = begin
               File.stat(filename)
             rescue Errno::ENOENT
             end
      stat or return
      if digest = file_digest_cached?(filename, stat)
        digest
      else
        file_digest_store(filename, stat, compute_digest(File.read(filename)))
      end
    end
  end
end
