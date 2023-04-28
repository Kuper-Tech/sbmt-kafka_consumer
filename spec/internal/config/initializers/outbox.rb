# frozen_string_literal: true

Rails.application.config.outbox.tap do |config|
  config.inbox_item_classes << "TestInboxItem"
  config.paths << Rails.root.join("config/outbox.yml").to_s

  config.worker.tap do |wc|
    wc.rate_limit = 1000
    wc.rate_interval = 10
    wc.shuffle_jobs = false
  end
end
