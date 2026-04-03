# frozen_string_literal: true

module Hawk
  module Rails
    class Configuration
      LEVELS = {
        fatal: 1,
        error: 2,
        warning: 4,
        info: 8,
        debug: 16
      }.freeze

      attr_accessor :token,
                    :release,
                    :context,
                    :user,
                    :before_send,
                    :collector_endpoint,
                    :source_code_lines,
                    :enabled_environments,
                    :async

      def initialize
        @token = nil
        @release = nil
        @context = {}
        @user = nil
        @before_send = nil
        @collector_endpoint = nil
        @source_code_lines = 5
        @enabled_environments = %w[production staging]
        @async = true
      end

      def integration_id
        return nil unless @token

        decoded = JSON.parse(Base64.decode64(@token))
        decoded["integrationId"]
      rescue JSON::ParserError, ArgumentError
        nil
      end

      def resolved_endpoint
        @collector_endpoint || begin
          id = integration_id
          raise ConfigurationError, "Invalid integration token" unless id

          "https://#{id}.k1.hawk.so/"
        end
      end

      def valid?
        !@token.nil? && !@token.empty? && !integration_id.nil?
      end
    end

    class ConfigurationError < StandardError; end
  end
end
