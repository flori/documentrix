require 'spec_helper'

describe Documentrix::Documents::MemoryCache do
  let :prefix do
    'test-'
  end

  let :cache do
    described_class.new prefix:
  end

  it 'can be instantiated' do
    expect(cache).to be_a described_class
  end

  it 'can get/set a key' do
    key, value = 'foo', { test: true }
    expect {
      cache[key] = value
    }.to change {
      cache[key]
    }.from(nil).to(value)
  end

  it 'can determine if key exists' do
    key, value = 'foo', { test: true }
    expect {
      cache[key] = value
    }.to change {
      cache.key?(key)
    }.from(false).to(true)
  end

  it 'can set key with different prefixes' do
    key, value = 'foo', { test: true }
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
    key, value = 'foo', { test1: true }
    cache[key] = value
    cache.prefix = 'test2-'
    key, value = 'bar', { test2: true }
    cache[key] = value
    expect(cache.full_each.to_a).to eq(
      [["test-foo", {test1: true}], ["test2-bar", {test2: true}]]
    )
    cache.move_prefix('test-', 'test3-')
    expect(cache.full_each.to_a).to eq(
      [["test2-bar", {test2: true}], ["test3-foo", {test1: true}]]
    )
  end

  it 'can delete' do
    key, value = 'foo', { test: true }
    expect(cache.delete(key)).to be_falsy
    cache[key] = value
    expect {
      expect(cache.delete(key)).to eq true
    }.to change {
      cache.key?(key)
    }.from(true).to(false)
      expect(cache.delete(key)).to eq false
  end

  it 'can iterate over keys, values' do
    key, value = 'foo', { test: true }
    cache[key] = value
    cache.each do |k, v|
      expect(k).to eq prefix + key
      expect(v).to eq value
    end
    expect(cache.each.to_a).to eq [ ["test-foo", {test: true}] ]
    expect(cache.to_a).to eq [ ["test-foo", {test: true}] ]
  end

  it "can iterate over the full cache's keys, values" do
    key, value = 'foo', { test: true }
    cache[key] = value
    cache.prefix = 'test2-'
    key, value = 'bar', { test2: true }
    cache[key] = value
    expect(cache.full_each.to_a).to eq [
      ["test-foo", {test: true}],
      ["test2-bar", {test2: true}],
    ]
  end

  it 'returns size' do
    key, value = 'foo', { test: true }
    expect {
      cache[key] = value
    }.to change {
      cache.size
    }.from(0).to(1)
  end

  it 'can clear' do
    key, value = 'foo', { test: true }
    cache[key] = value
    expect {
      expect(cache.clear).to eq cache
    }.to change {
      cache.size
    }.from(1).to(0)
  end

  it 'can iterate over keys under a prefix' do
    cache['foo'] = 'bar'
    expect(cache.to_a).to eq [ %W[ #{prefix}foo bar ] ]
  end
end
