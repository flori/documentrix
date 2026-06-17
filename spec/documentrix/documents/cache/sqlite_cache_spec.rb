describe Documentrix::Documents::SQLiteCache do
  let :prefix do
    'test-'
  end

  let :test_value do
    {
      key:       'test',
      text:      'test text',
      norm:      0.5,
      source:    'for-test.txt',
      tags:      %w[ test ],
      embedding: [ 0.5 ] * 1_024,
    }
  end

  let :cache do
    described_class.new prefix:
  end

  it 'can be instantiated' do
    expect(cache).to be_a described_class
  end

  it 'defaults to :memory: mode' do
    expect(cache.filename).to eq ':memory:'
  end

  it 'can be switchted to file mode' do
    expect(SQLite3::Database).to receive(:new).with('foo.sqlite').
      and_return(double.as_null_object)
    cache = described_class.new prefix:, filename: 'foo.sqlite'
    expect(cache.filename).to eq 'foo.sqlite'
  end

  it 'can get/set a key' do
    key, value = 'foo', test_value
    queried_value = nil
    expect {
      cache[key] = value
    }.to change {
      queried_value = cache[key]
    }.from(nil).to(Documentrix::Documents::Record[value])
    expect(queried_value.embedding).to eq [ 0.5 ] * 1_024
  end

  it 'can determine if key exists' do
    key, value = 'foo', test_value
    expect {
      cache[key] = value
    }.to change {
      cache.key?(key)
    }.from(false).to(true)
  end

  it 'can set key with different prefixes' do
    key, value = 'foo', test_value
    expect {
      cache[key] = value
    }.to change {
      cache.size
    }.from(0).to(1)
    cache2 = cache.dup
    cache2.prefix = 'test2-'
    expect {
      cache2[key] = value
    }.to change {
      cache2.size
    }.from(0).to(1)
    expect(cache.size).to eq 1
    s = 0
    cache.full_each { s += 1 }
    expect(s).to eq 2
  end

  it 'can move prefixes' do
    key, value = 'foo', test_value
    cache[key] = value
    cache.prefix = 'test2-'
    key, value = 'bar', test_value
    cache[key] = value
    expect(cache.full_each.to_a).to eq(
      [
        ["test-foo", Documentrix::Documents::Record[test_value]],
        ["test2-bar", Documentrix::Documents::Record[test_value]],
      ]
    )
    cache.move_prefix('test-', 'test3-')
    expect(cache.full_each.to_a).to eq(
      [
        ["test3-foo", Documentrix::Documents::Record[test_value]],
        ["test2-bar", Documentrix::Documents::Record[test_value]],
      ]
    )
  end

  it 'can delete' do
    key, value = 'foo', test_value
    expect(cache.delete(key)).to be_falsy
    cache[key] = value
    expect {
      expect(cache.delete(key)).to eq true
    }.to change {
      cache.key?(key)
    }.from(true).to(false)
  end

  it 'returns size' do
    key, value = 'foo', test_value
    expect {
      cache[key] = value
    }.to change {
      cache.size
    }.from(0).to(1)
  end

  it 'can convert_to_vector' do
    vector = [ 23.0, 666.0 ]
    expect(cache.convert_to_vector(vector)).to eq vector
  end

  it 'can clear' do
    key, value = 'foo', { embedding: [ 0.5 ] * 1_024 }
    cache[key] = value
    expect {
      expect(cache.clear).to eq cache
    }.to change {
      cache.size
    }.from(1).to(0)
  end

  it 'can clear for tags' do
    key, value = 'foo', { tags: %w[ foo ], embedding: [ 0.5 ] * 1_024 }
    cache[key] = value
    key, value = 'bar', { embedding: [ 0.5 ] * 1_024 }
    cache[key] = value
    expect {
      expect(cache.clear_for_tags(%w[ #foo ])).to eq cache
    }.to change {
      cache.size
    }.from(2).to(1)
    expect(cache).not_to be_key 'foo'
    expect(cache).to be_key 'bar'
  end

  it 'can clear all without tags' do
    key, value = 'foo', { tags: %w[ foo ], embedding: [ 0.5 ] * 1_024 }
    cache[key] = value
    key, value = 'bar', { embedding: [ 0.5 ] * 1_024 }
    cache[key] = value
    expect {
      expect(cache.clear_for_tags).to eq cache
    }.to change {
      cache.size
    }.from(2).to(0)
    expect(cache).not_to be_key 'foo'
    expect(cache).not_to be_key 'bar'
  end

  it 'can clear by source' do
    val1 = test_value.merge(source: 's1')
    val2 = test_value.merge(source: 's1')
    val3 = test_value.merge(source: 's2')
    cache['foo'] = val1
    cache['bar'] = val2
    cache['baz'] = val3
    expect {
      cache.clear_by_source('s1')
    }.to change { cache.size }.from(3).to(1)
    expect(cache.key?('baz')).to be true
    expect(cache.key?('foo')).to be false
  end

  it 'can clear by source and digest' do
    allow(cache).to receive(:compute_file_digest).and_return('d1', 'd2', 'd3')
    cache['foo'] = test_value.merge(source: 's1') # d1
    cache['bar'] = test_value.merge(source: 's1') # d2
    cache['baz'] = test_value.merge(source: 's1') # d3

    # Clear those that match d1
    expect {
      cache.clear_by_source('s1', digest: 'd1')
    }.to change { cache.size }.from(3).to(2)
    expect(cache.key?('foo')).to be false
    expect(cache.key?('bar')).to be true

    # Clear those that do NOT match d2 (should clear baz)
    expect {
      cache.clear_by_source('s1', digest: 'd2', operator: '!=')
    }.to change { cache.size }.from(2).to(1)
    expect(cache.key?('baz')).to be false
    expect(cache.key?('bar')).to be true
  end

  describe '#source_exist?' do
    it 'returns true if source exists' do
      cache['foo'] = test_value
      expect(cache.source_exist?('for-test.txt')).to be true
      expect(cache.source_exist?('non-existent')).to be false
    end

    it 'filters by digest' do
      allow(cache).to receive(:compute_file_digest).and_return('d1', 'd2')
      cache['foo'] = test_value.merge(source: 's1') # d1
      cache['bar'] = test_value.merge(source: 's1') # d2

      expect(cache.source_exist?('s1', digest: 'd1')).to be true
      expect(cache.source_exist?('s1', digest: 'd3')).to be false
      expect(cache.source_exist?('s1', digest: 'd1', operator: '!=')).to be true # bar exists
      expect(cache.source_exist?('s1', digest: 'd2', operator: '!=')).to be true # foo exists
    end
  end

  it 'can return tags' do
    key, value = 'foo', { tags: %w[ foo ], embedding: [ 0.5 ] * 1_024 }
    cache[key] = value
    key, value = 'bar', { tags: %w[ bar baz ], embedding: [ 0.5 ] * 1_024 }
    cache[key] = value
    tags = cache.tags
    expect(tags).to be_a Documentrix::Utils::Tags
    expect(tags.to_a).to eq %w[ bar baz foo ]
  end

  it 'can iterate over unique sources' do
    val1 = test_value.merge(source: 's1')
    val2 = test_value.merge(source: 's1')
    val3 = test_value.merge(source: 's2')
    cache['foo'] = val1
    cache['bar'] = val2
    cache['baz'] = val3

    expect(cache.each_source.to_a).to match_array(['s1', 's2'])
  end

  it 'can iterate over keys under a prefix' do
    cache['foo'] = test_value
    expect(cache.each.to_a).to eq [ [ 'test-foo', Documentrix::Documents::Record[test_value] ] ]
    expect(cache.to_a).to eq [ [ 'test-foo', Documentrix::Documents::Record[test_value] ] ]
  end

  it "can iterate over the full cache's keys, values" do
    key, value = 'foo', test_value
    cache[key] = value
    cache.prefix = 'test2-'
    key, value = 'bar', test_value
    cache[key] = value
    expect(cache.full_each.to_a).to eq [
      ["test-foo", Documentrix::Documents::Record[test_value] ],
      ["test2-bar", Documentrix::Documents::Record[test_value] ],
    ]
  end

  describe 'Prefix Isolation' do
    let(:cache2) { cache.dup }

    before do
      cache2.prefix = 'other-'

      # Setup shared sources and tags across prefixes
      cache['foo'] = test_value.merge(source: 'shared.txt', tags: %w[ a ])
      cache2['bar'] = test_value.merge(source: 'shared.txt', tags: %w[ a ])
    end

    it 'does not leak clear_by_source' do
      expect {
        cache.clear_by_source('shared.txt')
      }.to change { cache.size }.from(1).to(0)

      expect(cache2.size).to eq 1
      expect(cache2.key?('bar')).to be true
    end

    it 'does not leak source_exist?' do
      # Ensure we are checking a source that ONLY exists in the other prefix
      cache.clear_all_with_prefix
      cache2['baz'] = test_value.merge(source: 'only-in-2.txt')

      expect(cache.source_exist?('only-in-2.txt')).to be false
      expect(cache2.source_exist?('only-in-2.txt')).to be true
    end

    it 'does not leak tags' do
      cache.clear_all_with_prefix
      cache2.clear_all_with_prefix

      cache['foo'] = test_value.merge(tags: %w[ prefix1 ])
      cache2['bar'] = test_value.merge(tags: %w[ prefix2 ])

      expect(cache.tags.to_a).to match_array(['prefix1'])
      expect(cache2.tags.to_a).to match_array(['prefix2'])
    end
  end

  describe '#find_records' do
    let(:needle) { [ 0.5 ] * 1_024 }

    it 'raises ArgumentError if needle length is incorrect' do
      expect {
        cache.find_records([ 0.1 ])
      }.to raise_error(ArgumentError, /needle embedding length/)
    end

    it 'returns the most similar record' do
      # Record 1: Exact match
      val1 = test_value.merge(text: 'match', embedding: needle)
      # Record 2: Different vector
      val2 = test_value.merge(text: 'diff', embedding: [ 0.1 ] * 1_024)

      cache['r1'] = val1
      cache['r2'] = val2

      results = cache.find_records(needle)

      expect(results.size).to eq 2
      expect(results.first.text).to eq 'match'
      expect(results.first.similarity).to be_within(0.001).of(1.0)
    end

    it 'filters results by tags' do
      val1 = test_value.merge(text: 'tagged', tags: %w[ a ], embedding: needle)
      val2 = test_value.merge(text: 'untagged', tags: %w[ b ], embedding: needle)

      cache['r1'] = val1
      cache['r2'] = val2

      expect(cache.find_records(needle, tags: %w[ a ]).map(&:text)).to eq %w[ tagged ]
      expect(cache.find_records(needle, tags: %w[ b ]).map(&:text)).to eq %w[ untagged ]
      expect(cache.find_records(needle, tags: %w[ c ]).size).to eq 0
    end

    it 'filters results by min_similarity' do
      # Exact match
      cache['r1'] = test_value.merge(text: 'match', embedding: needle)
      # Very different vector
      cache['r2'] = test_value.merge(text: 'diff', embedding: [ -0.5 ] * 1_024)

      # Low threshold: both should appear
      expect(cache.find_records(needle, min_similarity: -1).size).to eq 2

      # High threshold: only match should appear
      expect(cache.find_records(needle, min_similarity: 0.9).map(&:text)).to eq %w[ match ]
    end

    it 'limits results via max_records' do
      3.times do |i|
        cache["r#{i}"] = test_value.merge(text: "t#{i}", embedding: needle)
      end

      expect(cache.find_records(needle, max_records: 2).size).to eq 2
    end

    it 'returns empty array when no records match' do
      expect(cache.find_records(needle)).to eq []
    end
  end

  describe '#collections' do
    it 'extracts unique collection names matching the prefix' do
      # Since cache['key'] = val stores as "#{prefix}#{key}",
      # we can create keys like "col1-foo" to get "test-col1-foo"
      cache['col1-foo'] = test_value
      cache['col1-bar'] = test_value
      cache['col2-baz'] = test_value
      cache['justprefix'] = test_value # Matches prefix, but not the pattern "prefix(name)-"

      expect(cache.collections('test-')).to match_array([:col1, :col2])
    end

    it 'returns empty array when no keys match the prefix' do
      cache['foo'] = test_value
      expect(cache.collections('nonexistent-')).to eq []
    end

    it 'returns empty array when keys start with prefix but lack a following hyphen' do
      # We need a key that starts with "test-" but doesn't have another "-" later.
      # Because cache['foo'] = val results in "test-foo", this is exactly what happens.
      cache['foo'] = test_value
      expect(cache.collections('test-')).to eq []
    end
  end
end
