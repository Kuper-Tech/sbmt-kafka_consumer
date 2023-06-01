# Change Log

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](http://keepachangelog.com/)
and this project adheres to [Semantic Versioning](http://semver.org/).

## [Unreleased] - yyyy-mm-dd

### Added

### Changed

### Fixed

## [0.7.2] - 2023-06-01

### Fixed
- remove `ActiveRecord::Base::clear_active_connections!` after consumer db issues as it's already handled by karafka v2
- async metrics reporting for `statistics.emitted` event to prevent rdkafka's main thread hanging, see https://github.com/karafka/karafka/pull/1420/files

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
