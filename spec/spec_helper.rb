# frozen_string_literal: true

require "webmock/rspec"
require "json"
require "base64"

# Stub minimal Rails before loading our gem
require "rails"
require "action_dispatch"

# Create a minimal Rails application for testing
class TestApp < ::Rails::Application
  config.eager_load = false
  config.logger = Logger.new(nil)
  config.secret_key_base = "test-secret-key-base-for-hawk-rails-gem"
end

require "hawk/rails"

WebMock.disable_net_connect!

def build_token(integration_id: "test-integration-id", secret: "test-secret")
  Base64.strict_encode64(JSON.generate({
    integrationId: integration_id,
    secret: secret
  }))
end

RSpec.configure do |config|
  config.before(:each) do
    Hawk::Rails.reset!
  end

  config.expect_with :rspec do |expectations|
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end

  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end

  config.shared_context_metadata_behavior = :apply_to_host_groups
  config.filter_run_when_matching :focus
  config.order = :random
end
