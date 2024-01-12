# frozen_string_literal: true

require "rails_helper"

describe Sbmt::KafkaConsumer::ClientConfigurer do
  it "properly configures karafka routes" do
    described_class.configure!

    expect(SbmtKarafka::App.routes.count).to be(2)

    expect(SbmtKarafka::App.routes.first.to_h).to include(
      id: "some_name_cg_with_single_topic",
      topics: contain_exactly(
        hash_including(
          active: true,
          active_job: {active: false},
          dead_letter_queue: {active: false, max_retries: 3, topic: nil},
          declaratives: {active: true, details: {}, partitions: 1, replication_factor: 1},
          initial_offset: "earliest",
          kafka: {"auto.offset.reset": "latest"},
          manual_offset_management: {active: true},
          max_messages: 100,
          max_wait_time: 1000,
          name: "topic_with_inbox_items"
        )
      )
    )

    expect(SbmtKarafka::App.routes.last.to_h).to include(
      id: "some_name_cg_with_multiple_topics",
      topics: contain_exactly(hash_including(
        active: true,
        active_job: {active: false},
        dead_letter_queue: {active: false, max_retries: 3, topic: nil},
        declaratives: {active: true, details: {}, partitions: 1, replication_factor: 1},
        initial_offset: "earliest",
        kafka: hash_including(
          "allow.auto.create.topics": true,
          "bootstrap.servers": "kafka:9092",
          "client.id": "some-name",
          "client.software.name": "karafka",
          "heartbeat.interval.ms": 5000,
          "reconnect.backoff.max.ms": 3000,
          "security.protocol": "plaintext",
          "session.timeout.ms": 30000,
          "socket.connection.setup.timeout.ms": 5000,
          "socket.timeout.ms": 30000,
          "statistics.interval.ms": 5000,
          "topic.metadata.refresh.interval.ms": 5000
        ),
        manual_offset_management: {active: true},
        max_messages: 100,
        max_wait_time: 1000,
        name: "topic_with_json_data"
      ), hash_including(
        active: false,
        active_job: {active: false},
        dead_letter_queue: {active: false, max_retries: 3, topic: nil},
        declaratives: {active: true, details: {}, partitions: 1, replication_factor: 1},
        initial_offset: "earliest",
        kafka: hash_including(
          "allow.auto.create.topics": true,
          "bootstrap.servers": "kafka:9092",
          "client.id": "some-name",
          "client.software.name": "karafka",
          "heartbeat.interval.ms": 5000,
          "reconnect.backoff.max.ms": 3000,
          "security.protocol": "plaintext",
          "session.timeout.ms": 30000,
          "socket.connection.setup.timeout.ms": 5000,
          "socket.timeout.ms": 30000,
          "statistics.interval.ms": 5000,
          "topic.metadata.refresh.interval.ms": 5000
        ),
        manual_offset_management: {active: false},
        max_messages: 100,
        max_wait_time: 1000,
        name: "inactive_topic_with_autocommit"
      ), hash_including(
        active: true,
        active_job: {active: false},
        dead_letter_queue: {active: false, max_retries: 3, topic: nil},
        declaratives: {active: true, details: {}, partitions: 1, replication_factor: 1},
        initial_offset: "earliest",
        kafka: hash_including(
          "allow.auto.create.topics": true,
          "bootstrap.servers": "kafka:9092",
          "client.id": "some-name",
          "client.software.name": "karafka",
          "heartbeat.interval.ms": 5000,
          "reconnect.backoff.max.ms": 3000,
          "security.protocol": "plaintext",
          "session.timeout.ms": 30000,
          "socket.connection.setup.timeout.ms": 5000,
          "socket.timeout.ms": 30000,
          "statistics.interval.ms": 5000,
          "topic.metadata.refresh.interval.ms": 5000
        ),
        manual_offset_management: {active: true},
        max_messages: 100,
        max_wait_time: 1000,
        name: "topic_with_protobuf_data"
      ), hash_including(
        active: true,
        active_job: {active: false},
        dead_letter_queue: {active: false, max_retries: 3, topic: nil},
        declaratives: {active: true, details: {}, partitions: 1, replication_factor: 1},
        initial_offset: "earliest",
        kafka: hash_including(
          "allow.auto.create.topics": true,
          "bootstrap.servers": "kafka:9092",
          "client.id": "some-name",
          "client.software.name": "karafka",
          "heartbeat.interval.ms": 5000,
          "reconnect.backoff.max.ms": 3000,
          "security.protocol": "plaintext",
          "session.timeout.ms": 30000,
          "socket.connection.setup.timeout.ms": 5000,
          "socket.timeout.ms": 30000,
          "statistics.interval.ms": 5000,
          "topic.metadata.refresh.interval.ms": 5000
        ),
        manual_offset_management: {active: true},
        max_messages: 100,
        max_wait_time: 1000,
        name: "topic-name-with.dots-dashes_and_underscores"
      ))
    )
  end
end
