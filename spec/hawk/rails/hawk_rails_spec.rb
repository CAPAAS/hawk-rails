# frozen_string_literal: true

RSpec.describe Hawk::Rails do
  describe ".configure" do
    it "yields configuration" do
      described_class.configure do |config|
        config.token = "test-token"
      end

      expect(described_class.configuration.token).to eq("test-token")
    end
  end

  describe ".configuration" do
    it "returns a Configuration instance" do
      expect(described_class.configuration).to be_a(Hawk::Rails::Configuration)
    end

    it "returns the same instance" do
      config1 = described_class.configuration
      config2 = described_class.configuration

      expect(config1).to equal(config2)
    end
  end

  describe ".send" do
    it "delegates to Catcher" do
      token = build_token(integration_id: "test-id")
      described_class.configure do |config|
        config.token = token
        config.enabled_environments = [::Rails.env.to_s]
        config.async = false
      end

      stub_request(:post, "https://test-id.k1.hawk.so/")
        .to_return(status: 200)

      error = RuntimeError.new("manual send")
      error.set_backtrace([])

      expect { described_class.send(error, context: { manual: true }) }.not_to raise_error
    end
  end

  describe ".reset!" do
    it "resets configuration" do
      described_class.configure do |config|
        config.token = "old-token"
      end

      described_class.reset!

      expect(described_class.configuration.token).to be_nil
    end
  end

  describe "VERSION" do
    it "has a version number" do
      expect(Hawk::Rails::VERSION).not_to be_nil
      expect(Hawk::Rails::VERSION).to match(/\A\d+\.\d+\.\d+/)
    end
  end
end
