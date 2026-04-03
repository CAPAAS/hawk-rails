# frozen_string_literal: true

module Hawk
  module Rails
    class Railtie < ::Rails::Railtie
      initializer "hawk_rails.configure" do |app|
        app.middleware.insert_before(0, Hawk::Rails::Middleware)
      end

      config.after_initialize do
        if Hawk::Rails.configuration.valid?
          ::Rails.logger&.info("[Hawk] Catcher initialized for #{::Rails.env}")
        else
          ::Rails.logger&.warn("[Hawk] Integration token is not configured. Set it in config/initializers/hawk.rb")
        end
      end
    end
  end
end
