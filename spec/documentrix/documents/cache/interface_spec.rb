require 'spec_helper'

describe 'Documentrix::Documents::Cache Interface' do
  describe 'MemoryCache Interface' do
    let(:cache) { Documentrix::Documents::MemoryCache.new(prefix: 'test-') }

    it 'has proper method resolution' do
      # Basic cache operations
      expect(cache).to respond_to(:[])
      expect(cache.method(:[]).owner).to eq Documentrix::Documents::MemoryCache

      expect(cache).to respond_to(:[]=)
      expect(cache.method(:[]=).owner).to eq Documentrix::Documents::MemoryCache

      expect(cache).to respond_to(:key?)
      expect(cache.method(:key?).owner).to eq Documentrix::Documents::MemoryCache

      expect(cache).to respond_to(:delete)
      expect(cache.method(:delete).owner).to eq Documentrix::Documents::MemoryCache

      expect(cache).to respond_to(:size)
      expect(cache.method(:size).owner).to eq Documentrix::Documents::MemoryCache

      expect(cache).to respond_to(:clear_all_with_prefix)
      expect(cache.method(:clear_all_with_prefix).owner).to eq Documentrix::Documents::MemoryCache

      expect(cache).to respond_to(:each)
      expect(cache.method(:each).owner).to eq Documentrix::Documents::MemoryCache

      expect(cache).to respond_to(:full_each)
      expect(cache.method(:full_each).owner).to eq Documentrix::Documents::MemoryCache

      # Common methods from Cache::Common
      expect(cache).to respond_to(:collections)
      expect(cache.method(:collections).owner).to eq Documentrix::Documents::Cache::Common

      expect(cache).to respond_to(:pre)
      expect(cache.method(:pre).owner).to eq Documentrix::Documents::Cache::Common

      expect(cache).to respond_to(:unpre)
      expect(cache.method(:unpre).owner).to eq Documentrix::Documents::Cache::Common

      expect(cache).to respond_to(:find_records)
      expect(cache.method(:find_records).owner).to eq Documentrix::Documents::Cache::Common

      expect(cache).to respond_to(:tags)
      expect(cache.method(:tags).owner).to eq Documentrix::Documents::Cache::Common

      expect(cache).to respond_to(:clear_for_tags)
      expect(cache.method(:clear_for_tags).owner).to eq Documentrix::Documents::Cache::Common

      expect(cache).to respond_to(:clear)
      expect(cache.method(:clear).owner).to eq Documentrix::Documents::Cache::Common
    end
  end

  describe 'RedisCache Interface' do
    let(:cache) { Documentrix::Documents::RedisCache.new(prefix: 'test-', url: 'redis://localhost:6379') }

    it 'has proper method resolution' do
      # Basic cache operations
      expect(cache).to respond_to(:[])
      expect(cache.method(:[]).owner).to eq Documentrix::Documents::RedisCache

      expect(cache).to respond_to(:[]=)
      expect(cache.method(:[]=).owner).to eq Documentrix::Documents::RedisCache

      expect(cache).to respond_to(:key?)
      expect(cache.method(:key?).owner).to eq Documentrix::Documents::RedisCache

      expect(cache).to respond_to(:delete)
      expect(cache.method(:delete).owner).to eq Documentrix::Documents::RedisCache

      expect(cache).to respond_to(:size)
      expect(cache.method(:size).owner).to eq Documentrix::Documents::RedisCache

      expect(cache).to respond_to(:clear_all_with_prefix)
      expect(cache.method(:clear_all_with_prefix).owner).to eq Documentrix::Documents::RedisCache

      expect(cache).to respond_to(:each)
      expect(cache.method(:each).owner).to eq Documentrix::Documents::RedisCache

      expect(cache).to respond_to(:full_each)
      expect(cache.method(:full_each).owner).to eq Documentrix::Documents::Cache::Records::RedisFullEach

      # Common methods from Cache::Common
      expect(cache).to respond_to(:collections)
      expect(cache.method(:collections).owner).to eq Documentrix::Documents::Cache::Common

      expect(cache).to respond_to(:pre)
      expect(cache.method(:pre).owner).to eq Documentrix::Documents::Cache::Common

      expect(cache).to respond_to(:unpre)
      expect(cache.method(:unpre).owner).to eq Documentrix::Documents::Cache::Common

      expect(cache).to respond_to(:find_records)
      expect(cache.method(:find_records).owner).to eq Documentrix::Documents::Cache::Common

      expect(cache).to respond_to(:tags)
      expect(cache.method(:tags).owner).to eq Documentrix::Documents::Cache::Common

      expect(cache).to respond_to(:clear_for_tags)
      expect(cache.method(:clear_for_tags).owner).to eq Documentrix::Documents::Cache::Common

      expect(cache).to respond_to(:clear)
      expect(cache.method(:clear).owner).to eq Documentrix::Documents::Cache::Common

      # Redis-specific methods
      expect(cache).to respond_to(:redis)
      expect(cache.method(:redis).owner).to eq Documentrix::Documents::RedisCache
    end
  end

  describe 'RedisBackedMemoryCache Interface' do
    before do
      allow(Documentrix::Documents::RedisCache).to receive(:new).and_return(
        double('RedisCache', full_each: true)
      )
    end

    let(:cache) { Documentrix::Documents::RedisBackedMemoryCache.new(prefix: 'test-', url: 'redis://localhost:6379') }

    it 'has proper method resolution' do
      # Basic cache operations (inherited from MemoryCache)
      expect(cache).to respond_to(:[])
      expect(cache.method(:[]).owner).to eq Documentrix::Documents::MemoryCache

      expect(cache).to respond_to(:[]=)
      expect(cache.method(:[]=).owner).to eq Documentrix::Documents::RedisBackedMemoryCache

      expect(cache).to respond_to(:key?)
      expect(cache.method(:key?).owner).to eq Documentrix::Documents::MemoryCache

      expect(cache).to respond_to(:delete)
      expect(cache.method(:delete).owner).to eq Documentrix::Documents::RedisBackedMemoryCache

      expect(cache).to respond_to(:size)
      expect(cache.method(:size).owner).to eq Documentrix::Documents::MemoryCache

      expect(cache).to respond_to(:clear_all_with_prefix)
      expect(cache.method(:clear_all_with_prefix).owner).to eq Documentrix::Documents::RedisBackedMemoryCache

      expect(cache).to respond_to(:each)
      expect(cache.method(:each).owner).to eq Documentrix::Documents::MemoryCache

      expect(cache).to respond_to(:full_each)
      expect(cache.method(:full_each).owner).to eq Documentrix::Documents::Cache::Records::RedisFullEach

      # Common methods from Cache::Common
      expect(cache).to respond_to(:collections)
      expect(cache.method(:collections).owner).to eq Documentrix::Documents::Cache::Common

      expect(cache).to respond_to(:pre)
      expect(cache.method(:pre).owner).to eq Documentrix::Documents::Cache::Common

      expect(cache).to respond_to(:unpre)
      expect(cache.method(:unpre).owner).to eq Documentrix::Documents::Cache::Common

      expect(cache).to respond_to(:find_records)
      expect(cache.method(:find_records).owner).to eq Documentrix::Documents::Cache::Common

      expect(cache).to respond_to(:tags)
      expect(cache.method(:tags).owner).to eq Documentrix::Documents::Cache::Common

      expect(cache).to respond_to(:clear_for_tags)
      expect(cache.method(:clear_for_tags).owner).to eq Documentrix::Documents::Cache::Common

      expect(cache).to respond_to(:clear)
      expect(cache.method(:clear).owner).to eq Documentrix::Documents::Cache::Common

      # Redis-specific methods
      expect(cache).to respond_to(:redis)
      expect(cache.method(:redis).owner).to eq Documentrix::Documents::RedisBackedMemoryCache
    end
  end

  describe 'SQLiteCache Interface' do
    let(:cache) { Documentrix::Documents::Cache::SQLiteCache.new(prefix: 'test-') }

    it 'has proper method resolution' do
      # Basic cache operations
      expect(cache).to respond_to(:[])
      expect(cache.method(:[]).owner).to eq Documentrix::Documents::Cache::SQLiteCache

      expect(cache).to respond_to(:[]=)
      expect(cache.method(:[]=).owner).to eq Documentrix::Documents::Cache::SQLiteCache

      expect(cache).to respond_to(:key?)
      expect(cache.method(:key?).owner).to eq Documentrix::Documents::Cache::SQLiteCache

      expect(cache).to respond_to(:delete)
      expect(cache.method(:delete).owner).to eq Documentrix::Documents::Cache::SQLiteCache

      expect(cache).to respond_to(:size)
      expect(cache.method(:size).owner).to eq Documentrix::Documents::Cache::SQLiteCache

      expect(cache).to respond_to(:clear_all_with_prefix)
      expect(cache.method(:clear_all_with_prefix).owner).to eq Documentrix::Documents::Cache::SQLiteCache

      expect(cache).to respond_to(:each)
      expect(cache.method(:each).owner).to eq Documentrix::Documents::Cache::SQLiteCache

      expect(cache).to respond_to(:full_each)
      expect(cache.method(:full_each).owner).to eq Documentrix::Documents::Cache::SQLiteCache

      # Common methods from Cache::Common
      expect(cache).to respond_to(:collections)
      expect(cache.method(:collections).owner).to eq Documentrix::Documents::Cache::Common

      expect(cache).to respond_to(:pre)
      expect(cache.method(:pre).owner).to eq Documentrix::Documents::Cache::Common

      expect(cache).to respond_to(:unpre)
      expect(cache.method(:unpre).owner).to eq Documentrix::Documents::Cache::Common

      expect(cache).to respond_to(:find_records)
      expect(cache.method(:find_records).owner).to eq Documentrix::Documents::Cache::SQLiteCache

      expect(cache).to respond_to(:tags)
      expect(cache.method(:tags).owner).to eq Documentrix::Documents::Cache::SQLiteCache

      expect(cache).to respond_to(:clear_for_tags)
      expect(cache.method(:clear_for_tags).owner).to eq Documentrix::Documents::Cache::SQLiteCache

      expect(cache).to respond_to(:clear)
      expect(cache.method(:clear).owner).to eq Documentrix::Documents::Cache::Common

      # SQLite-specific methods
      expect(cache).to respond_to(:filename)
      expect(cache.method(:filename).owner).to eq Documentrix::Documents::Cache::SQLiteCache

      expect(cache).to respond_to(:embedding_length)
      expect(cache.method(:embedding_length).owner).to eq Documentrix::Documents::Cache::SQLiteCache

      expect(cache).to respond_to(:convert_to_vector)
      expect(cache.method(:convert_to_vector).owner).to eq Documentrix::Documents::Cache::SQLiteCache

      expect(cache).to respond_to(:find_records_for_tags)
      expect(cache.method(:find_records_for_tags).owner).to eq Documentrix::Documents::Cache::SQLiteCache
    end
  end
end
