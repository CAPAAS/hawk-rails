# frozen_string_literal: true

RSpec.describe Hawk::Rails::BacktraceParser do
  describe "#parse" do
    it "parses a standard Ruby backtrace line" do
      backtrace = ["/app/controllers/users_controller.rb:42:in `show'"]

      allow(Hawk::Rails::SourceCodeReader).to receive(:read).and_return(nil)

      result = described_class.new(backtrace).parse

      expect(result.size).to eq(1)
      expect(result[0][:file]).to eq("/app/controllers/users_controller.rb")
      expect(result[0][:line]).to eq(42)
      expect(result[0][:function]).to eq("show")
      expect(result[0][:column]).to eq(0)
    end

    it "handles backtrace lines without method name" do
      backtrace = ["/app/config/boot.rb:5"]

      allow(Hawk::Rails::SourceCodeReader).to receive(:read).and_return(nil)

      result = described_class.new(backtrace).parse

      expect(result.size).to eq(1)
      expect(result[0][:file]).to eq("/app/config/boot.rb")
      expect(result[0][:line]).to eq(5)
      expect(result[0][:function]).to be_nil
    end

    it "includes source code when available" do
      backtrace = ["/app/models/user.rb:10:in `validate_email'"]
      source = [
        { line: 8, content: "  def validate_email" },
        { line: 9, content: "    unless email.include?('@')" },
        { line: 10, content: "      raise 'Invalid email'" },
        { line: 11, content: "    end" },
        { line: 12, content: "  end" }
      ]

      allow(Hawk::Rails::SourceCodeReader).to receive(:read).and_return(source)

      result = described_class.new(backtrace).parse

      expect(result[0][:sourceCode]).to eq(source)
    end

    it "handles nil backtrace" do
      result = described_class.new(nil).parse
      expect(result).to eq([])
    end

    it "skips unparseable lines" do
      backtrace = ["some random text without line numbers"]

      result = described_class.new(backtrace).parse
      expect(result).to eq([])
    end

    it "parses multiple backtrace lines" do
      backtrace = [
        "/app/controllers/api/v1/users_controller.rb:15:in `create'",
        "/app/models/user.rb:42:in `save!'",
        "/app/lib/validator.rb:7:in `call'"
      ]

      allow(Hawk::Rails::SourceCodeReader).to receive(:read).and_return(nil)

      result = described_class.new(backtrace).parse

      expect(result.size).to eq(3)
      expect(result.map { |r| r[:file] }).to eq([
        "/app/controllers/api/v1/users_controller.rb",
        "/app/models/user.rb",
        "/app/lib/validator.rb"
      ])
    end
  end
end
