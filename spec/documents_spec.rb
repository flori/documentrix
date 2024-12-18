require 'spec_helper'

RSpec.describe Documentrix::Documents do
  let :ollama do
    double('Ollama::Client')
  end

  let :model do
    'mxbai-embed-large'
  end

  let :documents do
    described_class.new ollama:, model:
  end

  it 'can be instantiated' do
    expect(documents).to be_a described_class
  end

  it 'no texts can be added to it' do
    expect(documents.add([])).to eq documents
  end

  it 'texts can be added to it' do
    expect(ollama).to receive(:embed).
      with(model:, input: %w[ foo bar ], options: nil).
      and_return(double(embeddings: [ [ 0.1 ], [ 0.2 ] ]))
    expect(documents.add(%w[ foo bar ])).to eq documents
    expect(documents.exist?('foo')).to eq true
    expect(documents.exist?('bar')).to eq true
    expect(documents['foo']).to be_a Documentrix::Documents::Record
  end

  it 'a text can be added to it' do
    expect(ollama).to receive(:embed).
      with(model:, input: %w[ foo ], options: nil).
      and_return(double(embeddings: [ [ 0.1 ] ]))
    expect(documents << 'foo').to eq documents
    expect(documents.exist?('foo')).to eq true
    expect(documents.exist?('bar')).to eq false
    expect(documents['foo']).to be_a Documentrix::Documents::Record
  end

  it 'a text with can be added to it' do
    expect(ollama).to receive(:embed).
      with(model:, input: %w[ foo ], options: nil).
      and_return(double(embeddings: [ [ 0.1 ] ]))
    expect_any_instance_of(Documentrix::Utils::Tags).to\
      receive(:add).with('bar.rb', source: '/foo/bar.rb')
    expect(documents.add('foo', source: '/foo/bar.rb')).to eq documents
    expect(documents.exist?('foo')).to eq true
    expect(documents.exist?('bar')).to eq false
    expect(documents['foo']).to be_a Documentrix::Documents::Record
  end

  it 'can find strings' do
    expect(ollama).to receive(:embed).
      with(model:, input: [ 'foo' ], options: nil).
      and_return(double(embeddings: [ [ 0.1 ] ]))
    expect(documents << 'foo').to eq documents
    expect(ollama).to receive(:embed).
      with(model:, input: 'foo', options: nil).
      and_return(double(embeddings: [ [ 0.1 ] ]))
    records = documents.find('foo')
    expect(records).to eq [
      Documentrix::Documents::Record[text: 'foo', embedding: [ 0.1 ], similarity: 1.0 ]
    ]
    expect(records[0].to_s).to eq '#<Documentrix::Documents::Record "foo" 1.0>'
  end

  it 'can find only tagged strings' do
    expect(ollama).to receive(:embed).
      with(model:, input: [ 'foo' ], options: nil).
      and_return(double(embeddings: [ [ 0.1 ] ]))
    expect(documents.add('foo', tags: %w[ test ])).to eq documents
    expect(ollama).to receive(:embed).
      with(model:, input: 'foo', options: nil).
      and_return(double(embeddings: [ [ 0.1 ] ]))
    records = documents.find('foo', tags: %w[ nix ])
    expect(records).to eq []
    expect(ollama).to receive(:embed).
      with(model:, input: 'foo', options: nil).
      and_return(double(embeddings: [ [ 0.1 ] ]))
    records = documents.find('foo', tags: %w[ test ])
    expect(records).to eq [
      Documentrix::Documents::Record[text: 'foo', embedding: [ 0.1 ], similarity: 1.0 ]
    ]
    expect(records[0].to_s).to eq '#<Documentrix::Documents::Record "foo" #test 1.0>'
  end

  it 'can find strings conditionally' do
    expect(ollama).to receive(:embed).
      with(model:, input: [ 'foobar' ], options: nil).
      and_return(double(embeddings: [ [ 0.01 ] ]))
    expect(ollama).to receive(:embed).
      with(model:, input: [ 'foo' ], options: nil).
      and_return(double(embeddings: [ [ 0.1 ] ]))
    expect(documents << 'foobar').to eq documents
    expect(documents << 'foo').to eq documents
    expect(ollama).to receive(:embed).at_least(:once).
      with(model:, input: 'foo', options: nil).
      and_return(double(embeddings: [ [ 0.1 ] ]))
    records = documents.find_where('foo', text_count: 1)
    expect(records).to eq [
      Documentrix::Documents::Record[text: 'foo', embedding: [ 0.1 ], similarity: 1.0 ],
    ]
    records = documents.find_where('foo', text_size: 3)
    expect(records).to eq [
      Documentrix::Documents::Record[text: 'foo', embedding: [ 0.1 ], similarity: 1.0 ],
    ]
    records = documents.find_where('foo')
    expect(records).to eq [
      Documentrix::Documents::Record[text: 'foo', embedding: [ 0.1 ], similarity: 1.0 ],
      Documentrix::Documents::Record[text: 'foobar', embedding: [ 0.1 ], similarity: 1.0 ],
    ]
  end


  context 'it uses cache' do
    before do
      allow(ollama).to receive(:embed).
        with(model:, input: %w[ foo ], options: nil).
        and_return(double(embeddings: [ [ 0.1 ] ]))
    end

    it 'can delete texts' do
      expect(documents << 'foo').to eq documents
      expect {
        documents.delete('foo')
      }.to change { documents.exist?('foo') }.from(true).to(false)
    end

    it 'tracks size' do
      expect {
        expect(documents << 'foo').to eq documents
      }.to change { documents.size }.from(0).to(1)
    end

    it 'can clear texts' do
      expect(documents << 'foo').to eq documents
      expect {
        documents.clear
      }.to change { documents.size }.from(1).to(0)
    end

    it 'can clear texts with tags' do
      expect(ollama).to receive(:embed).
        with(model:, input: %w[ bar ], options: nil).
        and_return(double(embeddings: [ [ 0.1 ] ]))
      expect(documents.add('foo', tags: %w[ test ])).to eq documents
      expect(documents.add('bar', tags: %w[ test2 ])).to eq documents
      expect(documents.tags.to_a).to eq %w[ test test2 ]
      expect {
        documents.clear tags: 'test'
      }.to change { documents.size }.from(2).to(1)
      expect {
        documents.clear tags: :test2
      }.to change { documents.size }.from(1).to(0)
    end

    it 'returns collections' do
      expect(documents.collections).to eq [ :default ]
    end

    it 'can change collection' do
      expect(documents.instance_eval { @cache }).to receive(:prefix=).
        with(/#@collection/).and_call_original
      expect { documents.collection = :new_collection }.
        to change { documents.collection }.
        from(:default).
        to(:new_collection)
    end
  end
end
