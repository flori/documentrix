# Changes

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
