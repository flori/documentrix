describe Documentrix::Documents::RedisCache do
  let :object_class do
    Documentrix::Documents::Cache::Records::Record
  end

  let :prefix do
    'test-'
  end

  let :cache do
    described_class.new prefix:, url: 'something', object_class:
  end

  it 'can be instantiated' do
    expect(cache).to be_a described_class
  end

  it 'raises ArgumentError if url is missing' do
    expect {
      described_class.new prefix:, url: nil
    }.to raise_error ArgumentError
  end

  context 'test redis interactions' do
    let :redis do
      double('Redis')
    end

    before do
      allow_any_instance_of(described_class).to receive(:redis).and_return(redis)
    end

    it 'can be configured with object_class' do
      expect(cache.object_class).to eq object_class
    end

    it 'has Redis client' do
      expect(cache.redis).to eq redis
    end

    it 'can get a key' do
      key = 'foo'
      expect(redis).to receive(:get).with(prefix + key).and_return '"some_json"'
      expect(cache[key]).to eq 'some_json'
    end

    it 'can set a value for a key' do
      key, value = 'foo', { test: true }
      expect(redis).to receive(:set).with(prefix + key, JSON(value))
      cache[key] = value
    end

    it 'can determine if key exists' do
      key = 'foo'
      expect(redis).to receive(:exists?).with(prefix + key).and_return(false, true)
      expect(cache.key?('foo')).to eq false
      expect(cache.key?('foo')).to eq true
    end

    it 'can move prefixes' do
      expect(redis).to receive(:get).with(prefix + 'foo').and_return(object_class[foo: true].to_json)
      expect(redis).to receive(:get).with('test2-bar').and_return(object_class[foo: true].to_json)
      expect(redis).to receive(:set).with('test3-foo', /"foo":true/)
      expect(redis).to receive(:del).with('test-foo')
      expect(redis).to receive(:scan_each).with(match: ?*).
        and_yield("#{prefix}foo").
        and_yield("test2-bar")
      cache.move_prefix('test-', 'test3-')
    end

    it 'can delete' do
      key = 'foo'
      expect(redis).to receive(:del).with(prefix + key).and_return 1
      expect(cache.delete(key)).to eq true
      expect(redis).to receive(:del).with(prefix + key).and_return 0
      expect(cache.delete(key)).to eq false
    end

    it 'can iterate over keys, values' do
      key, value = 'foo', object_class[test: true]
      expect(redis).to receive(:set).with(prefix + key, object_class[value].to_json)
      cache[key] = value
      expect(redis).to receive(:scan_each).with(match: "#{prefix}*").
        and_yield("#{prefix}foo")
      expect(redis).to receive(:get).with(prefix + key).and_return(object_class[test: true].to_json)
      cache.each do |k, v|
        expect(k).to eq prefix + key
        expect(v).to eq value
      end
    end

    it 'returns size' do
      expect(redis).to receive(:scan_each).with(match: "#{prefix}*").
        and_yield("#{prefix}foo").
        and_yield("#{prefix}bar").
        and_yield("#{prefix}baz")
      expect(cache.size).to eq 3
    end

    it 'can clear' do
      expect(redis).to receive(:scan_each).with(match: 'test-*').and_yield(
        'test-foo'
      )
      expect(redis).to receive(:del).with('test-foo')
      expect(cache.clear).to eq cache
    end

    it 'can clear by source' do
      object_class = Class.new(JSON::GenericObject)
      cache = described_class.new(prefix:, url: 'something', object_class:)
      expect(redis).to receive(:scan_each).with(match: 'test-*').and_yield(
        'test-foo'
      ).and_yield(
        'test-bar'
      )
      expect(redis).to receive(:get).with('test-foo').and_return(JSON(source: 's1'))
      expect(redis).to receive(:get).with('test-bar').and_return(JSON(source: 's2'))
      expect(redis).to receive(:del).with('test-foo')
      expect(cache.clear_by_source('s1')).to eq cache
    end

    it 'can iterate over keys under a prefix' do
      expect(redis).to receive(:scan_each).with(match: 'test-*')
      cache.to_a
    end

    it 'can compute prefix with pre' do
      expect(cache.pre('foo')).to eq 'test-foo'
    end

    it 'can remove prefix with unpre' do
      expect(cache.unpre('test-foo')).to eq 'foo'
    end

    it 'can iterate over unique sources' do
      expect(redis).to receive(:scan_each).with(match: "#{prefix}*").and_yield(
        "#{prefix}foo"
      ).and_yield(
        "#{prefix}bar"
      )
      expect(redis).to receive(:get).with("#{prefix}foo").and_return(JSON(source: 's1'))
      expect(redis).to receive(:get).with("#{prefix}bar").and_return(JSON(source: 's2'))

      expect(cache.each_source.to_a).to match_array(['s1', 's2'])
    end

    it 'can retrieve all unique tags' do
      expect(redis).to receive(:scan_each).with(match: "#{prefix}*").and_yield(
        "#{prefix}foo"
      ).and_yield(
        "#{prefix}bar"
      )
      expect(redis).to receive(:get).with("#{prefix}foo").and_return(JSON(source: 's1', tags: ['a', 'b']))
      expect(redis).to receive(:get).with("#{prefix}bar").and_return(JSON(source: 's2', tags: ['b', 'c']))

      expect(cache.tags.to_a).to match_array(['a', 'b', 'c'])
    end

    it 'can clear records by tags' do
      expect(redis).to receive(:scan_each).with(match: "#{prefix}*").and_yield(
        "#{prefix}foo"
      ).and_yield(
        "#{prefix}bar"
      )
      expect(redis).to receive(:get).with("#{prefix}foo").and_return(JSON(source: 's1', tags: ['trash']))
      expect(redis).to receive(:get).with("#{prefix}bar").and_return(JSON(source: 's2', tags: ['keep']))
      expect(redis).to receive(:del).with("#{prefix}foo")

      expect(cache.clear_for_tags(['trash'])).to eq cache
    end

    it 'can check if a source exists with a specific digest' do
      expect(redis).to receive(:scan_each).with(match: "#{prefix}*").and_yield(
        "#{prefix}foo"
      )
      expect(redis).to receive(:get).with("#{prefix}foo").and_return(JSON(source: 's1', digest: 'd1'))

      expect(cache.source_exist?('s1', digest: 'd1')).to be true

      # Reset for the negative case
      expect(redis).to receive(:scan_each).with(match: "#{prefix}*").and_yield(
        "#{prefix}foo"
      )
      expect(redis).to receive(:get).with("#{prefix}foo").and_return(JSON(source: 's1', digest: 'd1'))
      expect(cache.source_exist?('s1', digest: 'd2')).to be false
    end
  end
end
