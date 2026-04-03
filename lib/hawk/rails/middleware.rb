# frozen_string_literal: true

module Hawk
  module Rails
    class Middleware
      def initialize(app)
        @app = app
      end

      def call(env)
        @app.call(env)
      rescue Exception => e
        begin
          request = ActionDispatch::Request.new(env) if defined?(ActionDispatch::Request)

          request_info = if request
            {
              url: request.url,
              method: request.request_method,
              headers: extract_headers(env),
              params: safe_params(request),
              ip: request.remote_ip
            }
          end

          user = extract_user(env)

          Catcher.instance.send_event(e, request_info: request_info, user: user)
        rescue
          nil
        end

        raise
      end

      private

      def extract_headers(env)
        env.each_with_object({}) do |(key, value), headers|
          next unless key.start_with?("HTTP_")
          next if key == "HTTP_COOKIE"

          header_name = key.sub("HTTP_", "").split("_").map(&:capitalize).join("-")
          headers[header_name] = value
        end
      end

      def safe_params(request)
        request.filtered_parameters
      rescue
        {}
      end

      def extract_user(env)
        return nil unless defined?(::Warden) || env["warden"]

        warden = env["warden"]
        return nil unless warden

        current_user = warden.user
        return nil unless current_user

        {
          id: current_user.try(:id)&.to_s,
          name: current_user.try(:name) || current_user.try(:email),
          url: nil
        }.compact
      rescue
        nil
      end
    end
  end
end
