# Documentrix is a Ruby library designed to facilitate the creation and
# querying of vector databases for natural language processing and large
# language model applications. It provides functionality for storing and
# retrieving dense vector embeddings of text strings, supporting various cache
# backends including memory, Redis, and SQLite for efficient data management.
module Documentrix
  module Utils
  end
end

require 'set'
require 'json'
require 'infobar'
require 'tins'
require 'documentrix/version'
require 'documentrix/utils'
require 'documentrix/documents'
