[![Gem Version](https://badge.fury.io/rb/sbmt-kafka_consumer.svg)](https://badge.fury.io/rb/sbmt-kafka_consumer)
[![Build Status](https://github.com/SberMarket-Tech/sbmt-kafka_consumer/actions/workflows/tests.yml/badge.svg?branch=master)](https://github.com/SberMarket-Tech/sbmt-kafka_consumer/actions?query=branch%3Amaster)

# Sbmt-KafkaConsumer

This gem is used to consume Kafka messages. It is a wrapper over the [Karafka](https://github.com/karafka/karafka) gem, and is recommended for use as a transport with the [sbmt-outbox](https://github.com/SberMarket-Tech/sbmt-outbox) gem.

## Installation

Add this line to your application's Gemfile:

```ruby
gem "sbmt-kafka_consumer"
```

And then execute:

```bash
bundle install
```

## Demo

Learn how to use this gem and how it works with Ruby on Rails at here https://github.com/SberMarket-Tech/outbox-example-apps

## Auto configuration

We recommend going through the configuration and file creation process using the following Rails generators. Each generator can be run by using the `--help` option to learn more about the available arguments.

### Initial configuration

If you plug the gem into your application for the first time, you can generate the initial configuration:

```shell
rails g kafka_consumer:install
```

As the result, the `config/kafka_consumer.yml` file will be created.

### Consumer class

A consumer class can be generated with the following command:

```shell
rails g kafka_consumer:consumer MaybeNamespaced::Name
```

### Inbox consumer

To generate an Inbox consumer for use with gem [sbmt-outbox](https://github.com/SberMarket-Tech/sbmt-outbox), run the following command:

```shell
rails g kafka_consumer:inbox_consumer MaybeNamespaced::Name some-consumer-group some-topic
```

## Manual configuration

The `config/kafka_consumer.yml` file is a main configuration for the gem.

Example config with a full set of options:

```yaml
default: &default
  client_id: "my-app-consumer"
  concurrency: 4 # max number of threads
  # optional Karafka options
  max_wait_time: 1
  shutdown_timeout: 60
  pause_timeout: 1
  pause_max_timeout: 30
  pause_with_exponential_backoff: true
  partition_assignment_strategy: cooperative-sticky
  auth:
    kind: plaintext
  kafka:
    servers: "kafka:9092"
    # optional Kafka options
    heartbeat_timeout: 5
    session_timeout: 30
    reconnect_timeout: 3
    connect_timeout: 5
    socket_timeout: 30
    kafka_options:
      allow.auto.create.topics: true
  probes: # optional section
    port: 9394
    endpoints:
      readiness:
        enabled: true
        path: "/readiness"
      liveness:
        enabled: true
        path: "/liveness"
        timeout: 15
        max_error_count: 15 # default 10
  metrics: # optional section
    port: 9090
    path: "/metrics"
  consumer_groups:
    group_ref_id_1:
      name: cg_with_single_topic
      topics:
        - name: topic_with_inbox_items
          consumer:
            klass: "Sbmt::KafkaConsumer::InboxConsumer"
            init_attrs:
              name: "test_items"
              inbox_item: "TestInboxItem"
          deserializer:
            klass: "Sbmt::KafkaConsumer::Serialization::NullDeserializer"
          kafka_options:
            auto.offset.reset: latest
    group_ref_id_2:
      name: cg_with_multiple_topics
      topics:
        - name: topic_with_json_data
          consumer:
            klass: "SomeConsumer"
          deserializer:
            klass: "Sbmt::KafkaConsumer::Serialization::JsonDeserializer"
        - name: topic_with_protobuf_data
          consumer:
            klass: "SomeConsumer"
          deserializer:
            klass: "Sbmt::KafkaConsumer::Serialization::ProtobufDeserializer"
            init_attrs:
              message_decoder_klass: "SomeDecoder"
              skip_decoding_error: true

development:
  <<: *default

test:
  <<: *default
  deliver: false

production:
  <<: *default
```

### `auth` config section

The gem supports 2 variants: plaintext (default) and SASL-plaintext

SASL-plaintext:

```yaml
auth:
  kind: sasl_plaintext
  sasl_username: user
  sasl_password: pwd
  sasl_mechanism: SCRAM-SHA-512
```

### `kafka` config section

The `servers` key is required and should be in rdkafka format: without `kafka://` prefix, for example: `srv1:port1,srv2:port2,...`.

The `kafka_config` section may contain any [rdkafka option](https://github.com/confluentinc/librdkafka/blob/master/CONFIGURATION.md). Also, `kafka_options` may be redefined for each topic.
Please note that the `partition.assignment.strategy` option within kafka_options is not supported for topics; instead, use the global option partition_assignment_strategy. 

### `consumer_groups` config section

```yaml
consumer_groups:
  # group id can be used when starting a consumer process (see CLI section below)
  group_id:
    name: some_group_name # required
    topics:
    - name: some_topic_name # required
      active: true # optional, default true
      consumer:
        klass: SomeConsumerClass # required, a consumer class inherited from Sbmt::KafkaConsumer::BaseConsumer
        init_attrs: # optional, consumer class attributes (see below)
          key: value
      deserializer:
        klass: SomeDeserializerClass # optional, default NullDeserializer, a deserializer class inherited from Sbmt::KafkaConsumer::Serialization::NullDeserializer
        init_attrs: # optional, deserializer class attributes (see below)
          key: value
      kafka_options: # optional, this section allows to redefine the root rdkafka options for each topic
        auto.offset.reset: latest
```

#### `consumer.init_attrs` options for `BaseConsumer`

- `skip_on_error` - optional, default false, omit consumer errors in message processing and commit the offset to Kafka
- `middlewares` - optional, default [], type String, add middleware before message processing
- `batch_middlewares` - optional, default [], type String, add middleware before batch message processing

```yaml
init_attrs:
  middlewares: ['SomeMiddleware']
  batch_middlewares: ['SomeBatchMiddleware']
```

```ruby
class SomeMiddleware
  def call(message)
    yield if message.payload.id.to_i % 2 == 0
  end
end

class SomeBatchMiddleware
  def call(message, consumer)
    yield
  end
end
```
__CAUTION__:
- ⚠️ `yield` is mandatory for all middleware, as it returns control to the `process_message/process_batch` method.
- ⚠️ all middlewares must take either 1 or 2 parameters.

#### `consumer.init_attrs` options for `InboxConsumer`

- `inbox_item` - required, name of the inbox item class
- `event_name` - optional, default nil, used when the inbox item keep several event types
- `skip_on_error` - optional, default false, omit consumer errors in message processing and commit the offset to Kafka
- `middlewares` - optional, default [], type String, add middleware before message processing
- `batch_middlewares` - optional, default [], type String, add middleware before batch message processing

```yaml
init_attrs:
  middlewares: ['SomeMiddleware']
  batch_middlewares: ['SomeBatchMiddleware']
```

```ruby
class SomeMiddleware
  def call(message)
    yield if message.payload.id.to_i % 2 == 0
  end
end

class SomeBatchMiddleware
  def call(message, consumer)
    yield
  end
end
```
__CAUTION__:
- ⚠️ `yield` is mandatory for all middleware, as it returns control to the `process_message` method.
- ⚠️ all middlewares must take either 1 or 2 parameters.

#### `deserializer.init_attrs` options

- `skip_decoding_error` — don't raise an exception when cannot deserialize the message

### Middlewares for all consumersа

To add middleware for all consumers, define them in the configuration

```ruby
# config/initializers/kafka_consumer.rb

Sbmt::KafkaConsumer.process_message_middlewares.push(
  SomeMiddleware
)

Sbmt::KafkaConsumer.process_batch_middlewares(
  SomeBatchMiddleware
)
```
__CAUTION__:
- ⚠️ `yield` is mandatory for all middleware, as it returns control to the `process_message` method.
- ⚠️ all middlewares must take either 1 or 2 parameters.

### `probes` config section

In Kubernetes, probes are mechanisms used to assess the health of your application running within a container.

```yaml
probes:
  port: 9394 # optional, default 9394
  endpoints:
    liveness:
      enabled: true # optional, default true
      path: /liveness # optional, default "/liveness"
      timeout: 10 # optional, default 10, timeout in seconds after which the group is considered dead
    readiness:
      enabled: true # optional, default true
      path: /readiness/kafka_consumer # optional, default "/readiness/kafka_consumer"
```

### `metrics` config section

We use [Yabeda](https://github.com/yabeda-rb/yabeda) to collect [all kind of metrics](./lib/sbmt/kafka_consumer/yabeda_configurer.rb).

```yaml
metrics:
  port: 9090 # optional, default is probes.port
  path: /metrics # optional, default "/metrics"
```

### `Kafkafile`

You can create a `Kafkafile` in the root of your app to configure additional settings for your needs.

Example:

```ruby
require_relative "config/environment"

some-extra-configuration
```

### `Process batch`

To process messages in batches, you need to add the `process_batch` method in the consumer

```ruby
# app/consumers/some_consumer.rb
class SomeConsumer < Sbmt::KafkaConsumer::BaseConsumer
  def process_batch(messages)
    # some code 
  end
end
```
__CAUTION__:
- ⚠️ Inbox does not support batch insertion.
- ⚠️ If you want to use this feature, you need to process the stack atomically (eg: insert it into clickhouse in one request).

## CLI

Run the following command to execute a server

```shell
kafka_consumer -g some_group_id_1 -g some_group_id_2 -c 5
```

Where:
- `-g` - `group`, a consumer group id, if not specified, all groups from the config will be processed
- `-c` - `concurrency`, a number of threads, default is 4

### `concurrency` argument

[Concurrency and Multithreading](https://karafka.io/docs/Concurrency-and-multithreading/).

Don't forget to properly calculate and set the size of the ActiveRecord connection pool:
- each thread will utilize one db connection from the pool
- an application can have monitoring threads which can use db connections from the pool

Also pay attention to the number of processes of the server:
- `number_of_processes x concurrency` for topics with high data intensity can be equal to the number of partitions of the consumed topic
- `number_sof_processes x concurrency` for topics with low data intensity can be less than the number of partitions of the consumed topic

## Testing

To test your consumer with Rspec, please use [this shared context](./lib/sbmt/kafka_consumer/testing/shared_contexts/with_sbmt_karafka_consumer.rb)

### for payload
```ruby
require "sbmt/kafka_consumer/testing"

RSpec.describe OrderCreatedConsumer do
  include_context "with sbmt karafka consumer"

  it "works" do
    publish_to_sbmt_karafka(payload, deserializer: deserializer)
    expect { consume_with_sbmt_karafka }.to change(Order, :count).by(1)
  end
end
```

### for payloads
```ruby
require "sbmt/kafka_consumer/testing"

RSpec.describe OrderCreatedConsumer do
  include_context "with sbmt karafka consumer"

  it "works" do
    publish_to_sbmt_karafka_batch(payloads, deserializer: deserializer)
    expect { consume_with_sbmt_karafka }.to change(Order, :count).by(1)
  end
end
```

## Development

1. Prepare environment
```shell
dip provision
```

2. Run tests
```shell
dip rspec
```

3. Run linter
```shell
dip rubocop
```

4. Run Kafka server
```shell
dip up
```

5. Run consumer server
```shell
dip kafka-consumer
```
