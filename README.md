# Documentrix - Ruby library for embedding vector database

## Description

The Ruby library, Documentrix, is designed to provide a way to build and
query vector databases for applications in natural language processing
(NLP) and large language models (LLMs). It allows users to store and
retrieve dense vector embeddings for text strings.

## Installation (gem &amp; bundler)

To install Documentrix, you can use the following methods:

### Using the gem command

Type `gem install documentrix` in your terminal.

### Using Bundler

Add the line `gem 'documentrix'` to your Gemfile and run `bundle install` in
your terminal.

## Usage

In your own software the library can be used as shown in this example:

```ruby
# Require necessary libraries: ollama-ruby and documentrix
require 'ollama'
require 'documentrix'

# Initialize an Ollama client instance, pointing to a local server
ollama = Ollama::Client.new(base_url: 'http://localhost:11434')

# Create a new Documentrix documents instance
documents = Documentrix::Documents.new(
  ollama: ollama,
  model: 'mxbai-embed-large',
  collection: 'my-collection',
  cache: Documentrix::Documents::SQLiteCache
)

# Split sample text into individual chunks using recursive character splitting
splitter = Documentrix::Documents::Splitters::RecursiveCharacter.new
text     = "hay hay hay…" # Sample text data
chunks   = splitter.split(text)
documents.add(chunks)

# Search the document collection for matching records
query   = "What needles can you find in a haystack" # Search query
records = documents.find_where(
  query,
  prompt: 'Represent this sentence for searching relevant passages: %s',
  text_size: 4096,
  text_count: 10
)
```

## Download

The homepage of this library is located at

* https://github.com/flori/documentrix

## Author

<b>Documentrix</b> was written by [Florian Frank](mailto:flori@ping.de)

## License

This software is licensed under the <i>MIT</i> license.
