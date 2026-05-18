# Changes

## 2026-05-17 v0.3.0

### New Features

- **Source Tracking & Versioning**:
    - Introduced `Documentrix::Utils::Digests` for SHA256 hashing of strings
      and files, including an `mtime`-based cache.
    - Implemented source-based document management in `Documentrix::Documents`
      via `normalize_source`, `source_exist?`, `source_modified?`,
      `source_update`, and `source_remove`.
    - Updated `Documentrix::Documents#add` and
      `Documentrix::Documents#source_update` to support `digest` for version
      tracking.
- **Text Splitting**:
    - Added `Documentrix::Documents::Splitters::Common` to implement
      `force_split` behavior.
    - Integrated `force` splitting into `Character`, `RecursiveCharacter`, and
      `Semantic` splitters.
- **Cache Enhancements**:
    - Added `each_source` to `Documentrix::Documents::Cache::Common` and an
      optimized `SELECT DISTINCT source` implementation in
      `Documentrix::Documents::Cache::SQLiteCache`.
    - Added a SQLite trigger `delete_embedding_after_record` to automatically
      clean the `embeddings` table.

### Improvements & Refactorings

- **Search & Retrieval**:
    - Added `min_similarity` parameter to `Documentrix::Documents#find`,
      `Documentrix::Documents::Cache::Common#find_records`, and
      `Documentrix::Documents::Cache::SQLiteCache#find_records`.
    - Optimized `Documentrix::Documents::Cache::SQLiteCache#find_records` by
      moving similarity calculations into the SQL query using `1 -
      vec_distance_cosine`.
    - Simplified `Documentrix::Documents#find_where` by streamlining
      `take_while` logic and utilizing `opts[:max_records]`.
- **Cache Implementations**:
    - Made `object_class` a required keyword argument in
      `Documentrix::Documents::RedisCache#initialize`.
    - Refactored `Documentrix::Documents::Cache::Common#clear_by_source` and
      `Documentrix::Documents::Cache::Common#source_exist?` to use ternary
      operators.
    - Improved `Documentrix::Documents::Cache::SQLiteCache#each_source` and
      `Documentrix::Documents::Cache::SQLiteCache#find_records` for better
      robustness and formatting.
- **Documentation & Tooling**:
    - Expanded YARD documentation for
      `Documentrix::Documents::Splitters::Character`, `RecursiveCharacter`,
      `Semantic`, and `Documentrix::Utils::ColorizeTexts`.
    - Centralized RSpec configuration via a `.rspec` file.

### Bug Fixes

- Fixed an issue in `Documentrix::Documents#find` where `max_records` was
  hardcoded to `nil` when calling the cache.
- Adjusted default handling of `min_similarity` in
  `Documentrix::Documents#find` to use `min_similarity ||= -1` within the
  method body.

### Testing

- Significantly expanded test suites for `SQLiteCache`, `MemoryCache`, and
  `RedisCache`, specifically covering `each_source`, `tags`, `clear_for_tags`,
  and digest-based checks.
- Added new test cases in `spec/documents_spec.rb` for source management and
  `Documentrix::Documents#source_update`.
- Added `spec/utils/digests_spec.rb` and updated splitter specs to verify
  `force` splitting behavior.

## 2026-05-12 v0.2.0

### Added

- Implemented source-based document removal by adding the `remove` method to
  `Documentrix::Documents`.
- Added `clear_by_source` to `Documentrix::Documents::Cache::Common` as the
  default cache implementation.
- Added an optimized `clear_by_source` override in
  `Documentrix::Documents::Cache::SQLiteCache` utilizing a direct SQL `DELETE`
  query.

### Changed

- Updated `documentrix.gemspec` to use `rubygems_version` **4.0.10**.
- Updated `gem_hadar` dependency to **2.17.1**.

### Testing

- Expanded test coverage in `spec/documents_spec.rb`,
  `spec/documentrix/documents/cache/interface_spec.rb`, and all specific cache
  specs.

## 2026-03-31 v0.1.1

- Improved compatibility and reliability by ensuring the gem uses a stable,
  newer version **0.1.8** of `sqlite-vec`.

## 2026-03-29 v0.1.0

- Added `Documentrix::Documents#rename_collection` to rename a collection and
  delegate key moving to the cache.
- Extended `Documentrix::Documents::Cache::Common#pre` and `#unpre` to accept
  an optional `prefix` argument.
- Implemented `Documentrix::Documents::Cache::MemoryCache#move_prefix`,
  `RedisCache#move_prefix`, and `SQLiteCache#move_prefix` for atomic key
  mass‑move operations.
- Updated unit tests to cover the new rename and prefix‑moving functionality.
- Switched to `GemHadar::SimpleCov` for test coverage.
- Removed the `redis_backed_memory_cache` implementation and its spec.
- Added a `.utilsrc` configuration file defining blocks for `search`,
  `discover`, `strip_spaces`, `probe`, `ssh_tunnel`, `classify`, and
  `code_indexer`.
- Reordered Docker `apk add` commands and added friendly echo messages during
  image build and test phases.
- Added `fail_fast: true` flag to the Docker file definition.
- Added interface spec for cache implementations (`memory`, `Redis`, `SQLite`).
- Included `Set` requirement for older Ruby versions.
- Removed unused expiry functionality from `RedisCache`.
- Refactored cache system to use explicit inheritance, moving common methods
  into `Documentrix::Documents::Cache::Common` and renaming `clear` to
  `clear_all_with_prefix`.
- Updated documentation with detailed RDoc comments.
- Updated CI configuration to use `bundle exec` and cleaned up `Gemfile.lock`.
- Added `changelog` configuration in `Rakefile` to support `CHANGES.md`.

## 2025-12-20 v0.0.4

- Added `openssl-dev` to the package list in `.all_images.yml` for Docker
  builds
- Replaced `RSpec.describe` with `describe` for simplified syntax
- Updated Redis service image in `docker-compose.yml` from
  `valkey/valkey:7.2.8-alpine` to `valkey/valkey:**8.1.1-alpine**
- Updated `required_ruby_version` from `~> 3.1` to `>= 3.1` in `Rakefile` and
  `documentrix.gemspec`
- Updated `rubygems_version` from **3.6.9** to **4.0.2** in
  `documentrix.gemspec`
- Updated `gem_hadar` development dependency to ~**2.10** in
  `documentrix.gemspec`
- Changed `bundle update` to `bundle update --all` in `.all_images.yml`
- Added `fail_fast: true` and `ruby:4.0-rc-alpine` image configuration in
  `.all_images.yml`
- Added `RUN gem update --system` to ensure latest RubyGems version
- Added `RUN gem install bundler gem_hadar` to install required gems
- Changed `rm -f Gemfile.lock` to `bundle update` for dependency management
- Added `ruby:3.1-alpine` image configuration to test matrix
- Remove `.github` directory from package ignore list in `Rakefile`
- Update `rubygems` version from **3.6.7** to **3.6.9** in
  `documentrix.gemspec`

## 2025-11-12 v0.0.3

- Replaced `numo-narray` dependency with `numo-narray-alt` in `Rakefile` and
  `documentrix.gemspec` to prevent compilation issues
- Updated `all_images` development dependency version from `~> 0.6` to `~> 0.9`
  in `Rakefile`
- Updated `s.rubygems_version` from **3.6.7** to **3.7.2**
- Updated `gem_hadar` development dependency from `~> 1.20` to `~> 2.8`
- Added `openssl-dev` to the package list in `.all_images.yml` for Docker builds
- Removed duplicate `tags` method
- Replaced `RSpec.describe` with `describe` for simplified syntax
- Updated Redis service image in `docker-compose.yml` from
  `valkey/valkey:7.2.8-alpine` to `valkey/valkey:**8.1.1-alpine**`

## 2025-05-26 v0.0.2

* Documentrix::Utils::Tags enhancements for improved tagging functionality:
  * Added `valid_tag` parameter to `initialize` method with default value.
  * Introduced `DEFAULT_VALID_TAG` regular expression constant.
  * Updated `initialize` and `add` methods to use new `valid_tag` parameter.
  * Added `attr_reader` for `valid_tag`.
* Added `describe` block for `Tag` in `tags_spec.rb`.
  * Added three `it` blocks to test instantiation, default tag value trimming, and custom regex usage.
* Update `.envrc` file to include Redis connection settings:
  * Added `REDIS_URL` environment variable with value `redis://localhost:9736`
  * Created new `.envrc` file in the root directory.

## 2025-01-29 v0.0.1

* Added docker-compose redis
    * Added a `services` section to `docker-compose.yml`
    * Created Redis service with image `valkey/valkey:*7.2.8-alpine*` and specified ports
    * Configured Redis volumes, including mounting a Redis config file (`./redis/redis.conf`)
    * Created new file `redis/redis.conf` with Redis configuration settings
* Added support for **Ruby 3.4** to the Docker image
* Added copyright notice and permissions to `LICENSE` file
* Remove double quotes from `summary` field

## 2024-12-06 v0.0.0

  * Start
