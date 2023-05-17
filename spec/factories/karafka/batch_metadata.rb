# frozen_string_literal: true

FactoryBot.define do
  factory :messages_batch_metadata, class: "SbmtKarafka::Messages::BatchMetadata" do
    skip_create

    size { 0 }
    first_offset { 0 }
    sequence(:last_offset) { |nr| nr }
    topic { "topic" }
    partition { 0 }
    deserializer { ->(message) { message.raw_payload } }
    created_at { Time.now.utc }
    scheduled_at { Time.now.utc }
    processed_at { Time.now.utc }
  end
end
