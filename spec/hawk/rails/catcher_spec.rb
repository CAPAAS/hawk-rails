# frozen_string_literal: true

RSpec.describe Hawk::Rails::Catcher do
  let(:token) { build_token(integration_id: "test-id") }

  before do
    Hawk::Rails.configure do |config|
      config.token = token
      config.enabled_environments = [::Rails.env.to_s]
      config.async = false
    end
  end

  describe "#send_event" do
    it "sends event to the collector endpoint" do
      stub = stub_request(:post, "https://test-id.k1.hawk.so/")
        .to_return(status: 200, body: '{"ok":true}')

      error = RuntimeError.new("test error")
      error.set_backtrace(["/app/test.rb:10:in `run'"])
      allow(Hawk::Rails::SourceCodeReader).to receive(:read).and_return(nil)

      described_class.instance.send_event(error)

      expect(stub).to have_been_requested

      body = JSON.parse(WebMock::RequestRegistry.instance.requested_signatures.hash.keys.first.body)
      expect(body["payload"]["title"]).to eq("test error")
      expect(body["payload"]["type"]).to eq("RuntimeError")
      expect(body["catcherType"]).to eq("errors/ruby")
    end

    it "does not send when token is missing" do
      Hawk::Rails.configuration.token = nil

      error = RuntimeError.new("test")
      error.set_backtrace([])

      expect(Net::HTTP).not_to receive(:new)
      described_class.instance.send_event(error)
    end

    it "applies before_send hook" do
      stub = stub_request(:post, "https://test-id.k1.hawk.so/")
        .to_return(status: 200)

      Hawk::Rails.configuration.before_send = ->(event) {
        event[:payload][:title] = "modified"
        event
      }

      error = RuntimeError.new("original")
      error.set_backtrace([])

      described_class.instance.send_event(error)

      expect(stub).to have_been_requested
      body = JSON.parse(WebMock::RequestRegistry.instance.requested_signatures.hash.keys.first.body)
      expect(body["payload"]["title"]).to eq("modified")
    end

    it "drops event when before_send returns false" do
      Hawk::Rails.configuration.before_send = ->(_event) { false }

      error = RuntimeError.new("should be dropped")
      error.set_backtrace([])

      expect(Net::HTTP).not_to receive(:new)
      described_class.instance.send_event(error)
    end

    it "sends with custom context" do
      stub = stub_request(:post, "https://test-id.k1.hawk.so/")
        .to_return(status: 200)

      error = RuntimeError.new("context test")
      error.set_backtrace([])

      described_class.instance.send_event(error, context: { debug: true })

      expect(stub).to have_been_requested
      body = JSON.parse(WebMock::RequestRegistry.instance.requested_signatures.hash.keys.first.body)
      expect(body["payload"]["context"]["debug"]).to be true
    end

    it "sends with custom user" do
      stub = stub_request(:post, "https://test-id.k1.hawk.so/")
        .to_return(status: 200)

      error = RuntimeError.new("user test")
      error.set_backtrace([])

      described_class.instance.send_event(error, user: { id: "99", name: "Admin" })

      expect(stub).to have_been_requested
      body = JSON.parse(WebMock::RequestRegistry.instance.requested_signatures.hash.keys.first.body)
      expect(body["payload"]["user"]["id"]).to eq("99")
      expect(body["payload"]["user"]["name"]).to eq("Admin")
    end

    it "sends to custom endpoint" do
      Hawk::Rails.configuration.collector_endpoint = "https://custom.hawk.example.com/collect"

      stub = stub_request(:post, "https://custom.hawk.example.com/collect")
        .to_return(status: 200)

      error = RuntimeError.new("custom endpoint")
      error.set_backtrace([])

      described_class.instance.send_event(error)

      expect(stub).to have_been_requested
    end
  end
end
