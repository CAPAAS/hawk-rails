# frozen_string_literal: true

module Hawk
  module Rails
    class Event
      attr_reader :error, :context, :user, :request_info

      def initialize(error, context: nil, user: nil, request_info: nil)
        @error = error
        @context = context
        @user = user
        @request_info = request_info
      end

      def to_payload
        config = Hawk::Rails.configuration

        {
          token: config.token,
          catcherType: CATCHER_TYPE,
          payload: build_payload(config)
        }
      end

      private

      def build_payload(config)
        payload = {
          title: error.message,
          type: error.class.name,
          backtrace: parse_backtrace(config),
          release: config.release,
          catcherVersion: VERSION,
          context: merged_context(config),
          user: resolved_user(config),
          addons: build_addons
        }

        payload[:level] = determine_level
        payload.compact
      end

      def parse_backtrace(config)
        BacktraceParser.new(
          error.backtrace,
          source_lines: config.source_code_lines
        ).parse
      end

      def merged_context(config)
        result = {}
        result.merge!(config.context) if config.context.is_a?(Hash)
        result.merge!(@context) if @context.is_a?(Hash)
        result.merge!(request_context) if @request_info
        result.empty? ? nil : result
      end

      def request_context
        return {} unless @request_info

        {
          request: {
            url: @request_info[:url],
            method: @request_info[:method],
            headers: @request_info[:headers],
            params: @request_info[:params],
            ip: @request_info[:ip]
          }.compact
        }
      end

      def resolved_user(config)
        return @user if @user
        return config.user if config.user

        { id: generate_anonymous_id }
      end

      def generate_anonymous_id
        require "digest"
        ip = @request_info[:ip] if @request_info.is_a?(Hash)
        seed = ["hawk-anonymous", Socket.gethostname, ip].compact.join("-")
        Digest::SHA256.hexdigest(seed)[0..15]
      end

      def build_addons
        {
          rails: {
            version: ::Rails::VERSION::STRING,
            environment: ::Rails.env
          },
          ruby: {
            version: RUBY_VERSION,
            platform: RUBY_PLATFORM,
            engine: RUBY_ENGINE
          }
        }
      rescue NameError
        {
          ruby: {
            version: RUBY_VERSION,
            platform: RUBY_PLATFORM,
            engine: RUBY_ENGINE
          }
        }
      end

      def determine_level
        case error
        when SystemExit, SignalException, NoMemoryError, SystemStackError
          Configuration::LEVELS[:fatal]
        when ScriptError, SecurityError
          Configuration::LEVELS[:error]
        when RuntimeError, StandardError
          Configuration::LEVELS[:error]
        else
          Configuration::LEVELS[:error]
        end
      end
    end
  end
end
