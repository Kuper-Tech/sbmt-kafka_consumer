# frozen_string_literal: true

source "https://nexus.sbmt.io/repository/rubygems/"

gemspec

source "https://nexus.sbmt.io/repository/ruby-gems-sbermarket/" do
  gem "sbmt_karafka", "~> 2.0"

  group :development, :test do
    gem "sbmt-dev", ">= 0.7.0"
    gem "sbmt-outbox", ">= 4.1.0"
  end
end
