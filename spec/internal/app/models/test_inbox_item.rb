# frozen_string_literal: true

class TestInboxItem < Sbmt::Outbox::InboxItem
  def track_metrics_after_consume; end
end
