# frozen_string_literal: true

Rails.application.config.outbox.tap do |config|
  config.inbox_item_classes << "TestInboxItem"
  config.paths << Rails.root.join("config/outbox.yml").to_s
end
