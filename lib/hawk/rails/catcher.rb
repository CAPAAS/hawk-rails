# frozen_string_literal: true

require "singleton"

module Hawk
  module Rails
    class Catcher
      include Singleton

      def send_event(error, context: nil, user: nil, request_info: nil)
        return unless enabled?

        event = Event.new(error, context: context, user: user, request_info: request_info)
        payload = event.to_payload

        if (hook = Hawk::Rails.configuration.before_send)
          payload = hook.call(payload)
          return if payload == false
        end

        deliver(payload)
      rescue => e
        warn "[Hawk] Failed to process event: #{e.message}"
      end

      def self.reset!
        @singleton__instance__ = nil
        @singleton__mutex__ = Mutex.new
      end

      private

      def enabled?
        config = Hawk::Rails.configuration
        return false unless config.valid?

        if defined?(::Rails)
          config.enabled_environments.include?(::Rails.env.to_s)
        else
          true
        end
      end

      def deliver(payload)
        if Hawk::Rails.configuration.async
          Thread.new { post(payload) }
        else
          post(payload)
        end
      end

      def post(payload)
        endpoint = Hawk::Rails.configuration.resolved_endpoint
        uri = URI.parse(endpoint)

        http = Net::HTTP.new(uri.host, uri.port)
        http.use_ssl = (uri.scheme == "https")
        http.open_timeout = 5
        http.read_timeout = 10

        request = Net::HTTP::Post.new(uri.path.empty? ? "/" : uri.path)
        request["Content-Type"] = "application/json"
        request["Accept"] = "application/json"
        request.body = JSON.generate(payload)

        response = http.request(request)

        unless response.is_a?(Net::HTTPSuccess)
          warn "[Hawk] Failed to send event: HTTP #{response.code}"
        end
      rescue => e
        warn "[Hawk] Network error: #{e.message}"
      end
    end
  end
end
