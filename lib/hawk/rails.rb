# frozen_string_literal: true

require "json"
require "base64"
require "net/http"
require "uri"

require_relative "rails/version"
require_relative "rails/configuration"
require_relative "rails/event"
require_relative "rails/backtrace_parser"
require_relative "rails/source_code_reader"
require_relative "rails/catcher"
require_relative "rails/middleware"
require_relative "rails/railtie"

module Hawk
  module Rails
    CATCHER_TYPE = "errors/ruby"

    class << self
      attr_writer :configuration

      def configuration
        @configuration ||= Configuration.new
      end

      def configure
        yield(configuration)
      end

      def send(error, context: nil, user: nil)
        Catcher.instance.send_event(error, context: context, user: user)
      end

      def reset!
        @configuration = Configuration.new
        Catcher.reset!
      end
    end
  end
end
