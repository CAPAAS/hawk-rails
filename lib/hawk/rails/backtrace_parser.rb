# frozen_string_literal: true

module Hawk
  module Rails
    class BacktraceParser
      BACKTRACE_LINE_REGEX = /\A(.+):(\d+)(?::in\s+[`'](.+)')?\z/

      def initialize(backtrace, source_lines: 5)
        @backtrace = backtrace || []
        @source_lines = source_lines
      end

      def parse
        @backtrace.map { |line| parse_line(line) }.compact
      end

      private

      def parse_line(line)
        match = BACKTRACE_LINE_REGEX.match(line)
        return nil unless match

        file = match[1]
        line_number = match[2].to_i
        function = match[3]

        entry = {
          file: file,
          line: line_number,
          column: 0,
          function: function
        }

        source_code = SourceCodeReader.read(file, line_number, @source_lines)
        entry[:sourceCode] = source_code if source_code

        entry
      end
    end
  end
end
