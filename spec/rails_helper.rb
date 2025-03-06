# frozen_string_literal: true

require "spec_helper"
require "logger"
require "combustion"
require "factory_bot_rails"
require "dry-monads"
require "dry/monads/result"
require "sbmt/kafka_consumer/testing"
require "sbmt/kafka_consumer/instrumentation/sentry_tracer"
require "sbmt/kafka_consumer/instrumentation/open_telemetry_loader"

# when using with combustion, anyway is required earlier than rails
# so it's railtie does nothing, but that require is cached
# we must require it explicitly to force anyway autoload our configs
require "anyway/rails" if defined?(Rails::Railtie)

RSpec::Matchers.define_negated_matcher :not_increment_yabeda_counter, :increment_yabeda_counter
RSpec::Matchers.define_negated_matcher :not_update_yabeda_gauge, :update_yabeda_gauge

begin
  Combustion.initialize! :active_record do
    if ENV["LOG"].to_s.empty?
      config.logger = ActiveSupport::TaggedLogging.new(Logger.new(nil))
      config.log_level = :fatal
    else
      config.logger = ActiveSupport::TaggedLogging.new(Logger.new($stdout))
      config.log_level = :debug
    end

    config.i18n.available_locales = %i[ru en]
    config.i18n.default_locale = :ru
  end
rescue => e
  # Fail fast if application couldn't be loaded
  warn "💥 Failed to load the app: #{e.message}\n#{e.backtrace.join("\n")}"
  exit(1)
end

RSpec.configure do |config|
  config.include FactoryBot::Syntax::Methods
end

Sbmt::KafkaConsumer::ClientConfigurer.configure!

Dir["#{__dir__}/support/**/*.rb"].sort.each { |f| require f }
Dir["#{__dir__}/factories/**/*.rb"].sort.each { |f| require f }

require "sbmt/dev/testing/rails_configuration"
