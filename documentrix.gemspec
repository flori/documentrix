# -*- encoding: utf-8 -*-
# stub: documentrix 0.0.2 ruby lib

Gem::Specification.new do |s|
  s.name = "documentrix".freeze
  s.version = "0.0.2".freeze

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Florian Frank".freeze]
  s.date = "1980-01-02"
  s.description = "The Ruby library, Documentrix, is designed to provide a way to build and\nquery vector databases for applications in natural language processing\n(NLP) and large language models (LLMs). It allows users to store and\nretrieve dense vector embeddings for text strings.\n".freeze
  s.email = "flori@ping.de".freeze
  s.extra_rdoc_files = ["README.md".freeze, "lib/documentrix.rb".freeze, "lib/documentrix/documents.rb".freeze, "lib/documentrix/documents/cache/common.rb".freeze, "lib/documentrix/documents/cache/memory_cache.rb".freeze, "lib/documentrix/documents/cache/records.rb".freeze, "lib/documentrix/documents/cache/redis_backed_memory_cache.rb".freeze, "lib/documentrix/documents/cache/redis_cache.rb".freeze, "lib/documentrix/documents/cache/sqlite_cache.rb".freeze, "lib/documentrix/documents/splitters/character.rb".freeze, "lib/documentrix/documents/splitters/semantic.rb".freeze, "lib/documentrix/utils.rb".freeze, "lib/documentrix/utils/colorize_texts.rb".freeze, "lib/documentrix/utils/math.rb".freeze, "lib/documentrix/utils/tags.rb".freeze, "lib/documentrix/version.rb".freeze]
  s.files = [".envrc".freeze, ".yardopts".freeze, "CHANGES.md".freeze, "Gemfile".freeze, "LICENSE".freeze, "README.md".freeze, "Rakefile".freeze, "docker-compose.yml".freeze, "documentrix.gemspec".freeze, "lib/documentrix.rb".freeze, "lib/documentrix/documents.rb".freeze, "lib/documentrix/documents/cache/common.rb".freeze, "lib/documentrix/documents/cache/memory_cache.rb".freeze, "lib/documentrix/documents/cache/records.rb".freeze, "lib/documentrix/documents/cache/redis_backed_memory_cache.rb".freeze, "lib/documentrix/documents/cache/redis_cache.rb".freeze, "lib/documentrix/documents/cache/sqlite_cache.rb".freeze, "lib/documentrix/documents/splitters/character.rb".freeze, "lib/documentrix/documents/splitters/semantic.rb".freeze, "lib/documentrix/utils.rb".freeze, "lib/documentrix/utils/colorize_texts.rb".freeze, "lib/documentrix/utils/math.rb".freeze, "lib/documentrix/utils/tags.rb".freeze, "lib/documentrix/version.rb".freeze, "redis/redis.conf".freeze, "spec/assets/embeddings.json".freeze, "spec/documentrix/documents/cache/memory_cache_spec.rb".freeze, "spec/documentrix/documents/cache/redis_backed_memory_cache_spec.rb".freeze, "spec/documentrix/documents/cache/redis_cache_spec.rb".freeze, "spec/documentrix/documents/cache/sqlite_cache_spec.rb".freeze, "spec/documentrix/documents/splitters/character_spec.rb".freeze, "spec/documentrix/documents/splitters/semantic_spec.rb".freeze, "spec/documents_spec.rb".freeze, "spec/spec_helper.rb".freeze, "spec/utils/colorize_texts_spec.rb".freeze, "spec/utils/tags_spec.rb".freeze]
  s.homepage = "https://github.com/flori/documentrix".freeze
  s.licenses = ["MIT".freeze]
  s.rdoc_options = ["--title".freeze, "Documentrix - Ruby library for embedding vector database".freeze, "--main".freeze, "README.md".freeze]
  s.required_ruby_version = Gem::Requirement.new("~> 3.1".freeze)
  s.rubygems_version = "3.6.9".freeze
  s.summary = "Ruby library for embedding vector database".freeze
  s.test_files = ["spec/documentrix/documents/cache/memory_cache_spec.rb".freeze, "spec/documentrix/documents/cache/redis_backed_memory_cache_spec.rb".freeze, "spec/documentrix/documents/cache/redis_cache_spec.rb".freeze, "spec/documentrix/documents/cache/sqlite_cache_spec.rb".freeze, "spec/documentrix/documents/splitters/character_spec.rb".freeze, "spec/documentrix/documents/splitters/semantic_spec.rb".freeze, "spec/documents_spec.rb".freeze, "spec/spec_helper.rb".freeze, "spec/utils/colorize_texts_spec.rb".freeze, "spec/utils/tags_spec.rb".freeze]

  s.specification_version = 4

  s.add_development_dependency(%q<gem_hadar>.freeze, ["~> 2.2".freeze])
  s.add_development_dependency(%q<all_images>.freeze, ["~> 0.6".freeze])
  s.add_development_dependency(%q<rspec>.freeze, ["~> 3.2".freeze])
  s.add_development_dependency(%q<kramdown>.freeze, ["~> 2.0".freeze])
  s.add_development_dependency(%q<debug>.freeze, [">= 0".freeze])
  s.add_development_dependency(%q<simplecov>.freeze, [">= 0".freeze])
  s.add_runtime_dependency(%q<infobar>.freeze, ["~> 0.9".freeze])
  s.add_runtime_dependency(%q<json>.freeze, ["~> 2.0".freeze])
  s.add_runtime_dependency(%q<tins>.freeze, ["~> 1.34".freeze])
  s.add_runtime_dependency(%q<sqlite-vec>.freeze, ["~> 0.0".freeze])
  s.add_runtime_dependency(%q<sqlite3>.freeze, ["~> 2.0".freeze, ">= 2.0.1".freeze])
  s.add_runtime_dependency(%q<kramdown-ansi>.freeze, ["~> 0.0".freeze, ">= 0.0.1".freeze])
  s.add_runtime_dependency(%q<numo-narray>.freeze, ["~> 0.9".freeze])
  s.add_runtime_dependency(%q<redis>.freeze, ["~> 5.0".freeze])
  s.add_runtime_dependency(%q<more_math>.freeze, ["~> 1.1".freeze])
end
