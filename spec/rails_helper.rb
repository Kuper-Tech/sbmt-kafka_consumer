# frozen_string_literal: true

# Engine root is used by rails_configuration to correctly
# load fixtures and support files
require "pathname"
ENGINE_ROOT = Pathname.new(File.expand_path("..", __dir__))

require "spec_helper"
require "logger"
require "combustion"

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

require "rspec/rails"
# Add additional requires below this line. Rails is not loaded until this point!

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

RSpec.configure do |config|
  config.include FactoryBot::Syntax::Methods
  config.include ActiveSupport::Testing::TimeHelpers
  config.include ActionDispatch::TestProcess::FixtureFile

  if Rails::VERSION::STRING >= "7.1.0"
    config.fixture_paths = Rails.root.join("spec/fixtures")
  else
    config.fixture_path = Rails.root.join("spec/fixtures")
  end

  config.use_transactional_fixtures = true
  config.infer_spec_type_from_file_location!
  config.filter_rails_from_backtrace!
end

Sbmt::KafkaConsumer::ClientConfigurer.configure!

Dir["#{__dir__}/support/**/*.rb"].sort.each { |f| require f }
