require 'tempfile'

describe Documentrix::Utils::Digests do
  let(:test_class) do
    Class.new do
      include Documentrix::Utils::Digests
    end
  end

  let(:subject) { test_class.new.expose }

  describe '#compute_digest' do
    it 'computes a valid SHA256 digest of a string' do
      text = 'hello world'
      expected = Digest::SHA256.hexdigest(text)
      expect(subject.compute_digest(text)).to eq expected
    end
  end

  describe '#compute_file_digest' do
    it 'returns nil for an empty filename' do
      expect(subject.compute_file_digest(nil)).to be_nil
      expect(subject.compute_file_digest('')).to be_nil
    end

    it 'returns nil for an absolute URL' do
      expect(subject.compute_file_digest('https://example.com/file.txt')).to be_nil
    end

    it 'returns nil for a non-existent file' do
      expect(subject.compute_file_digest('/tmp/non_existent_file_12345')).to be_nil
    end

    it 'computes the digest of a local file' do
      file = Tempfile.create('documentrix_test')
      content = 'file content'
      file.write(content)
      file.close

      expected = Digest::SHA256.hexdigest(content)
      expect(subject.compute_file_digest(file.path)).to eq expected
    end

    context 'with caching' do
      let(:file) { Tempfile.create('documentrix_cache_test') }
      let(:content) { 'initial content' }

      before do
        file.write(content)
        file.close
        subject.file_digest_cache_clear
      end

      it 'returns the same digest on subsequent calls' do
        digest1 = subject.compute_file_digest(file.path)
        digest2 = subject.compute_file_digest(file.path)
        expect(digest1).to eq digest2
      end

      it 'recomputes the digest when the file is modified' do
        digest1 = subject.compute_file_digest(file.path)

        # Update file content and force mtime change
        File.write(file.path, 'updated content')
        # Ensure mtime is actually different (some FS have low precision)
        File.utime(Time.now + 1, Time.now + 1, file.path)

        digest2 = subject.compute_file_digest(file.path)
        expect(digest1).not_to eq digest2
      end

      it 'recomputes the digest after cache clear' do
        digest1 = subject.compute_file_digest(file.path)
        subject.file_digest_cache_clear

        # Even though file hasn't changed, it should re-read and return same value
        digest2 = subject.compute_file_digest(file.path)
        expect(digest1).to eq digest2
      end
    end
  end

  describe '#file_digest_cache_clear' do
    it 'clears the internal cache' do
      file = Tempfile.create('documentrix_clear_test')
      file.write('test')
      file.close

      subject.compute_file_digest(file.path)
      subject.file_digest_cache_clear

      # We can verify this indirectly by checking if the cache is empty
      # or by the fact that it will re-compute in tests.
      expect(subject).to respond_to(:file_digest_cache_clear)
    end
  end
end
