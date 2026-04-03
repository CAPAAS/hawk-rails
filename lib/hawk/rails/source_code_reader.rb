# frozen_string_literal: true

module Hawk
  module Rails
    class SourceCodeReader
      class << self
        def read(file, line_number, context_lines = 5)
          return nil unless file && File.exist?(file) && File.readable?(file)

          lines = File.readlines(file)
          start_line = [line_number - context_lines, 1].max
          end_line = [line_number + context_lines, lines.size].min

          (start_line..end_line).map do |n|
            {
              line: n,
              content: lines[n - 1]&.chomp || ""
            }
          end
        rescue Errno::ENOENT, Errno::EACCES
          nil
        end
      end
    end
  end
end
