# frozen_string_literal: true

RSpec.describe Hawk::Rails::Event do
  let(:token) { build_token }

  before do
    Hawk::Rails.configure do |config|
      config.token = token
    end
  end

  describe "#to_payload" do
    it "builds a valid event payload" do
      error = RuntimeError.new("Something broke")
      error.set_backtrace(["/app/test.rb:10:in `run'"])
      allow(Hawk::Rails::SourceCodeReader).to receive(:read).and_return(nil)

      event = described_class.new(error)
      payload = event.to_payload

      expect(payload[:token]).to eq(token)
      expect(payload[:catcherType]).to eq("errors/ruby")
      expect(payload[:payload][:title]).to eq("Something broke")
      expect(payload[:payload][:type]).to eq("RuntimeError")
      expect(payload[:payload][:catcherVersion]).to eq(Hawk::Rails::VERSION)
    end

    it "includes backtrace" do
      error = RuntimeError.new("test")
      error.set_backtrace(["/app/test.rb:10:in `run'", "/app/main.rb:5:in `start'"])
      allow(Hawk::Rails::SourceCodeReader).to receive(:read).and_return(nil)

      event = described_class.new(error)
      payload = event.to_payload

      backtrace = payload[:payload][:backtrace]
      expect(backtrace.size).to eq(2)
      expect(backtrace[0][:file]).to eq("/app/test.rb")
      expect(backtrace[0][:line]).to eq(10)
    end

    it "includes release when configured" do
      Hawk::Rails.configuration.release = "v1.2.3"

      error = RuntimeError.new("test")
      error.set_backtrace([])

      event = described_class.new(error)
      payload = event.to_payload

      expect(payload[:payload][:release]).to eq("v1.2.3")
    end

    it "merges global and event context" do
      Hawk::Rails.configuration.context = { app: "test" }

      error = RuntimeError.new("test")
      error.set_backtrace([])

      event = described_class.new(error, context: { request_id: "abc" })
      payload = event.to_payload

      expect(payload[:payload][:context][:app]).to eq("test")
      expect(payload[:payload][:context][:request_id]).to eq("abc")
    end

    it "uses provided user" do
      error = RuntimeError.new("test")
      error.set_backtrace([])

      user = { id: "42", name: "Test User" }
      event = described_class.new(error, user: user)
      payload = event.to_payload

      expect(payload[:payload][:user]).to eq(user)
    end

    it "generates anonymous user ID when no user specified" do
      error = RuntimeError.new("test")
      error.set_backtrace([])

      event = described_class.new(error)
      payload = event.to_payload

      expect(payload[:payload][:user][:id]).to be_a(String)
      expect(payload[:payload][:user][:id]).not_to be_empty
    end

    it "includes addons with Ruby/Rails info" do
      error = RuntimeError.new("test")
      error.set_backtrace([])

      event = described_class.new(error)
      payload = event.to_payload

      addons = payload[:payload][:addons]
      expect(addons[:ruby][:version]).to eq(RUBY_VERSION)
      expect(addons[:ruby][:engine]).to eq(RUBY_ENGINE)
    end

    it "includes request info in context" do
      error = RuntimeError.new("test")
      error.set_backtrace([])

      request_info = {
        url: "https://example.com/api/users",
        method: "POST",
        ip: "127.0.0.1",
        headers: { "Accept" => "application/json" },
        params: { name: "test" }
      }

      event = described_class.new(error, request_info: request_info)
      payload = event.to_payload

      request_ctx = payload[:payload][:context][:request]
      expect(request_ctx[:url]).to eq("https://example.com/api/users")
      expect(request_ctx[:method]).to eq("POST")
      expect(request_ctx[:ip]).to eq("127.0.0.1")
    end

    it "sets error level" do
      error = RuntimeError.new("test")
      error.set_backtrace([])

      event = described_class.new(error)
      payload = event.to_payload

      expect(payload[:payload][:level]).to eq(Hawk::Rails::Configuration::LEVELS[:error])
    end

    it "sets fatal level for SystemExit" do
      error = SystemExit.new("exit")
      error.set_backtrace([])

      event = described_class.new(error)
      payload = event.to_payload

      expect(payload[:payload][:level]).to eq(Hawk::Rails::Configuration::LEVELS[:fatal])
    end
  end
end
