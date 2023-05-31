# frozen_string_literal: true

require_relative "lib/sbmt/kafka_consumer/version"

Gem::Specification.new do |spec|
  spec.name = "sbmt-kafka_consumer"
  spec.version = Sbmt::KafkaConsumer::VERSION
  spec.authors = ["Ruby Platform Team"]

  spec.summary = "Kafka consumer abstraction with ability to use inbox-pattern"
  spec.description = spec.summary
  spec.homepage = "https://gitlab.sbmt.io/nstmrt/rubygems/sbmt-kafka_consumer"
  spec.required_ruby_version = ">= 2.7.0"

  spec.metadata["allowed_push_host"] = "https://nexus.sbmt.io"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage
  spec.metadata["changelog_uri"] = "#{spec.homepage}/-/blob/master/CHANGELOG.md"
  spec.metadata["rubygems_mfa_required"] = "false" # rubocop:disable Gemspec/RequireMFA

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir.chdir(__dir__) do
    `git ls-files -z`.split("\x0").reject do |f|
      (f == __FILE__) || f.match(%r{\A(?:(?:bin|test|spec|features)/|\.(?:git|travis|circleci)|appveyor)})
    end
  end
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "rails", ">= 5.1"
  spec.add_dependency "zeitwerk", "~> 2.3"
  spec.add_dependency "sbmt_karafka", "~> 2.0"
  spec.add_dependency "sentry-rails", "> 5.2.0"
  spec.add_dependency "sbmt-outbox", ">= 4.1.0"
  spec.add_dependency "yabeda", ">= 0.11"
  spec.add_dependency "anyway_config", ">= 2.4.0"
  spec.add_dependency "thor"
  spec.add_dependency "dry-struct"

  spec.add_development_dependency "appraisal", ">= 2.4"
  spec.add_development_dependency "bundler", ">= 2.3"
  spec.add_development_dependency "combustion", ">= 1.3"
  spec.add_development_dependency "rake", ">= 13.0"
  spec.add_development_dependency "sbmt-dev", ">= 0.7.0"
  spec.add_development_dependency "dry-monads", "~> 1.3"
  spec.add_development_dependency "factory_bot_rails"
  spec.add_development_dependency "pg"
  spec.add_development_dependency "google-protobuf"

  # let metrics and probes work in dev-mode with combustion
  # e.g. RAILS_ENV=development bundle exec kafka_consumer
  spec.add_development_dependency "yabeda-prometheus-mmap"
  spec.add_development_dependency "webrick"
  spec.add_development_dependency "rack"
  spec.add_development_dependency "http_health_check"
end
