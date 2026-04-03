# frozen_string_literal: true

RSpec.describe Hawk::Rails::SourceCodeReader do
  let(:temp_file) do
    file = Tempfile.new(["test_source", ".rb"])
    file.write((1..20).map { |n| "line #{n} content" }.join("\n"))
    file.flush
    file.path
  end

  after do
    File.delete(temp_file) if File.exist?(temp_file)
  end

  describe ".read" do
    it "reads lines around the target line" do
      result = described_class.read(temp_file, 10, 2)

      expect(result.size).to eq(5)
      expect(result.first[:line]).to eq(8)
      expect(result.last[:line]).to eq(12)
      expect(result.find { |l| l[:line] == 10 }[:content]).to eq("line 10 content")
    end

    it "handles line near the start of file" do
      result = described_class.read(temp_file, 1, 3)

      expect(result.first[:line]).to eq(1)
      expect(result.first[:content]).to eq("line 1 content")
    end

    it "handles line near the end of file" do
      result = described_class.read(temp_file, 20, 3)

      expect(result.last[:line]).to eq(20)
    end

    it "returns nil for non-existent file" do
      result = described_class.read("/nonexistent/file.rb", 5, 3)
      expect(result).to be_nil
    end

    it "returns nil when file is nil" do
      result = described_class.read(nil, 5, 3)
      expect(result).to be_nil
    end
  end
end
