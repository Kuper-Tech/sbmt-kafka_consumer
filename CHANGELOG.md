# Change Log

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](http://keepachangelog.com/)
and this project adheres to [Semantic Versioning](http://semver.org/).

## [Unreleased] - yyyy-mm-dd

### Added

### Changed

### Fixed

## [3.5.1] - 2025-04-18

### Fixed

- Rename `yabeda_kafka_consumer_consumer_group_rebalances` gauge to `yabeda_kafka_consumer_group_rebalances`
- Change type of `yabeda_kafka_consumer_group_rebalances` from `Counter` to `Gauge`

## [3.5.0] - 2025-04-17

### Added

- Increase default timeout to 300 seconds for better accommodation of temporary delays.
- Make liveness probe listener thread-safe using a mutex.
- Use monotonic clock for more accurate time measurements in liveness checks.
- Simplify liveness status checking logic.
- Support Rack v3

## [3.4.2] - 2025-04-02

### Fixed
- Properly resolve constant `YabedaConfigurer`

## [3.4.1] - 2025-03-06

### Fixed
- reset consumer offset lag metric to zero after cg rebalance to avoid reporting stale metrics

## [3.4.0] - 2025-01-27

### Added

- Added support for warning log level in LoggerListener error handling
- Consider duplicate messages as warnings in logs

### Changed

### Fixed

## [3.3.2] - 2024-12-27

### Fixed

- Fix gemspec URL

## [3.3.1] - 2024-12-26

### Fixed

- Fix initialize yabeda metrics

## [3.3.0] - 2024-09-30

### Added

- inheritance of kafka settings for topic

### Fixed

- support `karafka 2.4.12`
- properly report metrics for consumer offset lag when partition fetch assignment was lost

## [3.2.2] - 2024-09-23

### Fixed

- log OTEL `trace_id`

## [3.2.1] - 2024-09-20

### Fixed

- Limit Karafka version to less than 2.4.12 since `bootstrap.servers` has been made required

## [3.2.0] - 2024-09-17

### Added

- For synchronous messages and errors, we place logs in tags

## [3.1.0] - 2024-09-09

### Fixed

- Refactor consumer class initialization

## [3.0.0] - 2024-09-04

## BREAKING

- Drop support for Ruby 2.7
- Drop support for Rails 6.0
- Add support for Karafka 2.4

### Fixed

- Support consumer group mappers to support backward compatibility of consumer group naming

## [2.8.0] - 2024-09-09

### Fixed

- Refactor consumer class initialization

## [2.7.1] - 2024-08-01

### Fixed

- Add mock `mark_as_consumed` for tests

## [2.7.0] - 2024-07-30

### Changed

- When using strategy `cooperative-sticky`, method `mark_as_consumed` is used ([more details](https://github.com/karafka/karafka/wiki/FAQ#why-when-using-cooperative-sticky-rebalance-strategy-all-topics-get-revoked-on-rebalance))

## [2.6.1] - 2024-07-05

### Fixed

- Use the current `trace_id` instead of creating a new one

## [2.6.0] - 2024-07-01

### Added

- Added instrumentation for methods `process_message` and `mark_as_consumed!`

### Fixed

- From `do_consume(message)` to `yield`

## [2.5.0] - 2024-06-24

### Added

- Added option `max_error_count` for liveness probes, which is triggered when `librdkafka.error`

## [2.4.1] - 2024-06-15

### Fixed

- Fixed display of metrics `kafka_api_calls`  and `kafka_api_errors`

## [2.4.0] - 2024-06-06

### Added

- Added option `midlewares` to add middleware before message processing

## [2.3.1] - 2024-06-05

### Fixed

- Rename from `export_batch` to `process_batch`

## [2.3.0] - 2024-05-30

### Added

- New config option `partition_assignment_strategy`

### Changed

- Raise an exception when using the `partition.assignment.strategy` option within `kafka_options` for topics.

## [2.2.0] - 2024-05-13

### Changed

- Drop support for Rails 5.2
- Add support for Ruby 3.3

## [2.1.0] - 2024-05-13

### Added

- Implemented method `export_batch` for processing messages in batches

## [2.0.1] - 2024-05-08

### Fixed

- Limit the Karafka version to less than `2.4` because they dropped the consumer group mapping

## [2.0.0] - 2024-01-30

### Changed

- Remove `sbmt-dev`

## [1.0.0] - 2024-01-12

### Added

- Use mainstream karafka instead of custom fork

## [0.23.0] - 2024-01-12

### Added

- ability to override `kafka_options` for topic

## [0.22.0] - 2024-01-09

### Added

- removed useless `outbox_producer` param for `InboxConsumer` class
- removed useless log messages from `InboxConsumer` class

## [0.21.0] - 2024-01-09

### Fixed

- initialization of proxy consumer classes
- consumer class name in sentry's transaction name

## [0.20.0] - 2024-01-09

### Added

- New config options `metrics`
- `metrics.port` for a metrics port that is different from the probes port
- `metrics.path` for a metrics path

## [0.19.2] - 2023-10-18

### Fixed

- Stub kafka_client to prevent calls to librdkafka: fixes SEGFAULT in parallel tests

## [0.19.1] - 2023-10-05

### Fixed

- disable karafka's `config.strict_topics_namespacing`

## [0.19.0] - 2023-09-29

### Added

- `outbox_producer` configuration flag

## [0.18.4] - 2023-09-26

### Fixed

- Use `Rails.application.executor.wrap` instead manual AR connection clearing

## [0.18.3] - 2023-09-15

### Fixed

- Fix broken outbox item generator call in the `kafka_consumer:inbox_consumer` generator

## [0.18.2] - 2023-09-14

### Fixed

- Properly extract opentelemetry context from kafka message headers

## [0.18.1] - 2023-09-13

### Fixed

- Port `v0.17.5` (properly clear `ActiveRecord` connections in case `skip_on_error` option is used) to master (v0.18)

## [0.18.0] - 2023-09-11

### Added

- OpenTelemetry tracing

## [0.17.5] - 2023-09-13

### Fixed

- Properly clear `ActiveRecord` connections in case `skip_on_error` option is used

## [0.17.4] - 2023-09-05

### Fixed

- Latency metrics in seconds instead ms

## [0.17.3] - 2023-08-31

### Fixed

- Decreased sleep time on db error in a consumer

## [0.17.2] - 2023-08-16

### Fixed

- Fix `message.metadata.key` validation if key is an empty string

## [0.17.1] - 2023-08-08

### Fixed

- Check Idempotency-Key for a empty string

## [0.17.0] - 2023-08-07

### Added

- ability to configure consumer group mapper in `kafka_consumer.yml` (needed for proper migration from existing karafka v2 based consumers)
- ability to define/override inbox-item attributes in InboxConsumer

### Fixed
- report `kafka_consumer_inbox_consumes` metric with tag `status = skipped` (instead `failure`) if skip_on_error is enabled on InboxConsumer

## [0.16.0] - 2023-07-27

### Added

- additional tags (client, group_id, partition, topic) for metric `kafka_consumer_inbox_consumes`

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
