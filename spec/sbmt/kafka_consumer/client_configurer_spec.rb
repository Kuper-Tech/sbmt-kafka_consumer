# frozen_string_literal: true

require "rails_helper"

describe Sbmt::KafkaConsumer::ClientConfigurer do
  it "properly configures karafka routes" do
    described_class.configure!

    expect(Karafka::App.routes.count).to be(3)

    simple_route = Karafka::App.routes.first.to_h
    expect(simple_route).to include(
      id: "some_name_cg_with_single_topic",
      topics: contain_exactly(
        hash_including(
          active: true,
          initial_offset: "earliest",
          kafka: hash_including(
            "auto.offset.reset": "latest",
            "allow.auto.create.topics": true,
            "bootstrap.servers": "kafka:9092",
            "heartbeat.interval.ms": 5000,
            "reconnect.backoff.max.ms": 3000,
            "security.protocol": "plaintext",
            "session.timeout.ms": 30000,
            "socket.connection.setup.timeout.ms": 5000,
            "socket.timeout.ms": 30000
          ),
          manual_offset_management: {active: true},
          max_messages: 100,
          max_wait_time: 1000,
          name: "topic_with_inbox_items"
        )
      )
    )

    complex_routes = Karafka::App.routes.second.to_h
    expect(complex_routes[:id]).to eq("some_name_cg_with_multiple_topics")

    topics = complex_routes[:topics].sort_by { |topic| topic[:name] }
    expect(topics[0]).to include(
      active: false,
      initial_offset: "earliest",
      kafka: hash_including(
        "allow.auto.create.topics": true,
        "bootstrap.servers": "kafka:9092",
        "heartbeat.interval.ms": 5000,
        "reconnect.backoff.max.ms": 3000,
        "security.protocol": "plaintext",
        "session.timeout.ms": 30000,
        "socket.connection.setup.timeout.ms": 5000,
        "socket.timeout.ms": 30000
      ),
      manual_offset_management: {active: false},
      max_messages: 100,
      max_wait_time: 1000,
      name: "inactive_topic_with_autocommit",
      consumer_group_id: "some_name_cg_with_multiple_topics"
    )
    expect(topics[1]).to include(
      active: true,
      initial_offset: "earliest",
      kafka: hash_including(
        "allow.auto.create.topics": true,
        "bootstrap.servers": "kafka:9092",
        "heartbeat.interval.ms": 5000,
        "reconnect.backoff.max.ms": 3000,
        "security.protocol": "plaintext",
        "session.timeout.ms": 30000,
        "socket.connection.setup.timeout.ms": 5000,
        "socket.timeout.ms": 30000
      ),
      manual_offset_management: {active: true},
      max_messages: 100,
      max_wait_time: 1000,
      name: "topic-name-with.dots-dashes_and_underscores"
    )
    expect(topics[2]).to include(
      active: true,
      initial_offset: "earliest",
      kafka: hash_including(
        "allow.auto.create.topics": true,
        "bootstrap.servers": "kafka:9092",
        "heartbeat.interval.ms": 5000,
        "reconnect.backoff.max.ms": 3000,
        "security.protocol": "plaintext",
        "session.timeout.ms": 30000,
        "socket.connection.setup.timeout.ms": 5000,
        "socket.timeout.ms": 30000
      ),
      manual_offset_management: {active: true},
      max_messages: 100,
      max_wait_time: 1000,
      name: "topic_with_json_data"
    )
    expect(topics[3]).to include(
      active: true,
      initial_offset: "earliest",
      kafka: hash_including(
        "allow.auto.create.topics": true,
        "bootstrap.servers": "kafka:9092",
        "heartbeat.interval.ms": 5000,
        "reconnect.backoff.max.ms": 3000,
        "security.protocol": "plaintext",
        "session.timeout.ms": 30000,
        "socket.connection.setup.timeout.ms": 5000,
        "socket.timeout.ms": 30000
      ),
      manual_offset_management: {active: true},
      max_messages: 100,
      max_wait_time: 1000,
      name: "topic_with_protobuf_data"
    )

    wildcard_route = Karafka::App.routes.third.to_h
    expect(wildcard_route[:id]).to eq("some_name_cg_with_topic_wildcard")

    topics = wildcard_route[:topics].sort_by { |topic| topic[:name] }

    expect(topics[0]).to include(
      active: true,
      initial_offset: "earliest",
      kafka: hash_including(
        "allow.auto.create.topics": true,
        "bootstrap.servers": "kafka:9092",
        "heartbeat.interval.ms": 5000,
        "reconnect.backoff.max.ms": 3000,
        "security.protocol": "plaintext",
        "session.timeout.ms": 30000,
        "socket.connection.setup.timeout.ms": 5000,
        "socket.timeout.ms": 30000
      ),
      manual_offset_management: {active: true},
      max_messages: 100,
      max_wait_time: 1000,
      name: "topic_with_wildcard.1"
    )
    expect(topics[1]).to include(
      active: true,
      initial_offset: "earliest",
      kafka: hash_including(
        "allow.auto.create.topics": true,
        "bootstrap.servers": "kafka:9092",
        "heartbeat.interval.ms": 5000,
        "reconnect.backoff.max.ms": 3000,
        "security.protocol": "plaintext",
        "session.timeout.ms": 30000,
        "socket.connection.setup.timeout.ms": 5000,
        "socket.timeout.ms": 30000
      ),
      manual_offset_management: {active: true},
      max_messages: 100,
      max_wait_time: 1000,
      name: "topic_with_wildcard.2"
    )
  end
end
