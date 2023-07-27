# Change Log

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](http://keepachangelog.com/)
and this project adheres to [Semantic Versioning](http://semver.org/).

## [Unreleased] - yyyy-mm-dd

### Added

### Changed

### Fixed

## [0.15.0] - 2023-07-21

### Added

- `kafka_consumer:install` generator
- `kafka_consumer:consumer_group` generator
- `kafka_consumer:consumer` generator

## [0.14.2] - 2023-07-19

### Changed
- `.clear_all_connections!` is now called for all DB roles

## [0.14.1] - yyyy-mm-dd

### Added
- add label `api` for group `kafka_api`

### Changed
- README improvements

## [0.14.0] - 2023-07-06

### Added
- report message payload and headers to Sentry if consumer detailed logging is enabled

## [0.13.1] - 2023-07-05

### Added
- `event_key` callback added to `Sbmt::KafkaConsumer::InboxConsumer`

## [0.13.0] - 2023-06-20

### Changed
- logging / instrumentation improvements

## [0.12.0] - 2023-06-20

### Changed
- README improvements
- update sbmt-waterdrop (via sbmt-karafka) to fix karafka-rdkafka 0.13 compatibility issue

## [0.11.0] - 2023-06-13

### Added
- `skip_on_error` consumer option to skip message processing (and commit offsets) if exception was raised

## [0.10.0] - 2023-06-07

### Added
- `SimpleLoggingConsumer`, which just consumes/logs messages, can be used for debug purposes

## [0.9.0] - 2023-06-06

### Changed
- add custom `ConsumerMapper` to be consistent with KarafkaV1 consumer-group naming conventions (e.g. karafka v1 uses underscored client-id in consumer group name)
- reuse with_db_retry: release ActiveRecord conn everytime after message processing, in case there's a connection-pool degradation

## [0.8.0] - 2023-06-01

### Changed
- update sbmt-karafka to 2.1.3
- remove db retries logic as `ActiveRecord::Base::clear_active_connections!` is already handled by karafka v2 after processing a batch
- async metrics reporting for `statistics.emitted` event to prevent rdkafka's main thread hanging, see https://github.com/karafka/karafka/pull/1420/files
- use Rails logger by default
- use `$stdout.sync = true` in consumer server process to avoid STDOUT buffering issues in docker/k8s

## [0.7.1] - 2023-05-31

### Fixed
- db error logging in base consumer

## [0.7.0] - 2023-05-30

### Added
- add `Sbmt::KafkaConsumer::Instrumentation::LivenessListener` and `Sbmt::KafkaConsumer::Instrumentation::ReadinessListener` listeners
- add `probes` option
- add `HttpHealthCheck` server with probes' endpoints

## [0.6.1] - 2023-05-30

### Added
- set default `source: "KAFKA"` option when creating `inbox_item` in `InboxConsumer`

## [0.6.0] - 2023-05-29

### Added
- add `manual_offset_management` topic's option (defaults to true)
- add consumer `group_id` to inbox-item metadata (InboxConsumer)

## [0.5.1] - 2023-05-25

### Fixed
- sentry tracing when instrumentation event is not an exception
- payload deserialization if skip_decoding_error is enabled

## [0.5.0] - 2023-05-23

### Changed
- add default deserializer (NullDeserializer) to config
- refactor logging

## [0.4.0] - 2023-05-19

### Changed
- refactor consumer groups config

## [0.3.0] - 2023-05-19

### Added
- add timeout aliases to kafka config
- README actualization

## [0.2.0] - 2023-05-16

### Added
- implement consumer metrics

## [Unreleased] - 2023-05-03

### Added
- base config loader via AnywayConfig

### Changed

### Fixed

## [Unreleased] - 2023-04-26

### Added
- BaseConsumer
- InboxConsumer
- Instrumentation listeners: sentry, logger, yabeda

### Changed

### Fixed

## [Unreleased]

## [0.1.0] - 2023-04-19

- Initial release
