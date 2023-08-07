# frozen_string_literal: true

FactoryBot.define do
  factory :inbox_item, class: "TestInboxItem" do
    proto_payload { "test" }
    sequence :event_key
    bucket { 0 }
    event_name { "event-name" }
  end
end
