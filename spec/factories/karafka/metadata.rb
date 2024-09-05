# frozen_string_literal: true

FactoryBot.define do
  factory :messages_metadata, class: "Karafka::Messages::Metadata" do
    skip_create

    topic { "topic" }
    sequence(:offset) { |nr| nr }
    partition { 0 }
    deserializers {
      {
        payload: ->(message) { message.raw_payload }
      }
    }
    timestamp { Time.now.utc }
  end
end
