# frozen_string_literal: true

FactoryBot.define do
  factory :messages_message, class: "Karafka::Messages::Message" do
    skip_create

    transient do
      topic { "topic" }
      partition { 0 }
      timestamp { Time.now.utc }
    end

    raw_payload { "{}" }

    # rubocop:disable FactoryBot/FactoryAssociationWithStrategy
    metadata do
      build(
        :messages_metadata,
        topic: topic,
        partition: partition,
        timestamp: timestamp
      )
    end
    # rubocop:enable FactoryBot/FactoryAssociationWithStrategy
  end
end
