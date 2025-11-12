# vim: set filetype=ruby et sw=2 ts=2:

require 'gem_hadar'

GemHadar do
  name        'documentrix'
  module_type :module
  author      'Florian Frank'
  email       'flori@ping.de'
  homepage    "https://github.com/flori/#{name}"
  summary     'Ruby library for embedding vector database'
  description <<~EOT
    The Ruby library, Documentrix, is designed to provide a way to build and
    query vector databases for applications in natural language processing
    (NLP) and large language models (LLMs). It allows users to store and
    retrieve dense vector embeddings for text strings.
  EOT

  test_dir   'spec'
  ignore     '.*.sw[pon]', 'pkg', 'Gemfile.lock', '.AppleDouble', '.bundle',
    '.yardoc', 'doc', 'tags', 'errors.lst', 'cscope.out', 'coverage', 'tmp',
    'yard'
  package_ignore '.all_images.yml', '.tool-versions', '.gitignore', 'VERSION',
     '.rspec', *Dir.glob('.github/**/*', File::FNM_DOTMATCH)
  readme     'README.md'

  required_ruby_version  '~> 3.1'

  dependency 'infobar',         '~> 0.9'
  dependency 'json',            '~> 2.0'
  dependency 'tins',            '~> 1.34'
  dependency 'sqlite-vec',      '~> 0.0'
  dependency 'sqlite3',         '~> 2.0', '>= 2.0.1'
  dependency 'kramdown-ansi',   '~> 0.0', '>= 0.0.1'
  dependency 'numo-narray-alt', '~> 0.9'
  dependency 'redis',           '~> 5.0'
  dependency 'more_math',       '~> 1.1'

  development_dependency 'all_images', '~> 0.9'
  development_dependency 'rspec',      '~> 3.2'
  development_dependency 'kramdown',   '~> 2.0'
  development_dependency 'debug'
  development_dependency 'simplecov'

  licenses << 'MIT'

  clobber 'coverage'
end
