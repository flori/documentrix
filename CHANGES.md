# Changes

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
