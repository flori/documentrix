# Changes

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
