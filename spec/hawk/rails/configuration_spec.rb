# frozen_string_literal: true

RSpec.describe Hawk::Rails::Configuration do
  let(:token) { build_token }

  describe "#initialize" do
    it "sets default values" do
      config = described_class.new

      expect(config.token).to be_nil
      expect(config.release).to be_nil
      expect(config.context).to eq({})
      expect(config.user).to be_nil
      expect(config.before_send).to be_nil
      expect(config.collector_endpoint).to be_nil
      expect(config.source_code_lines).to eq(5)
      expect(config.enabled_environments).to eq(%w[production staging])
      expect(config.async).to be true
    end
  end

  describe "#integration_id" do
    it "decodes integration ID from token" do
      config = described_class.new
      config.token = build_token(integration_id: "my-project-id")

      expect(config.integration_id).to eq("my-project-id")
    end

    it "returns nil for invalid token" do
      config = described_class.new
      config.token = "not-valid-base64!!!"

      expect(config.integration_id).to be_nil
    end

    it "returns nil when token is nil" do
      config = described_class.new
      expect(config.integration_id).to be_nil
    end
  end

  describe "#resolved_endpoint" do
    it "builds endpoint from integration ID" do
      config = described_class.new
      config.token = build_token(integration_id: "abc-123")

      expect(config.resolved_endpoint).to eq("https://abc-123.k1.hawk.so/")
    end

    it "uses custom collector_endpoint when set" do
      config = described_class.new
      config.token = token
      config.collector_endpoint = "https://custom.example.com/collect"

      expect(config.resolved_endpoint).to eq("https://custom.example.com/collect")
    end

    it "raises ConfigurationError for invalid token" do
      config = described_class.new
      config.token = "invalid"

      expect { config.resolved_endpoint }.to raise_error(Hawk::Rails::ConfigurationError)
    end
  end

  describe "#valid?" do
    it "returns true for a valid token" do
      config = described_class.new
      config.token = token

      expect(config.valid?).to be true
    end

    it "returns false when token is nil" do
      config = described_class.new
      expect(config.valid?).to be false
    end

    it "returns false when token is empty" do
      config = described_class.new
      config.token = ""

      expect(config.valid?).to be false
    end
  end
end
