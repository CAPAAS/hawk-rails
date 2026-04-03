# frozen_string_literal: true

module HawkRails
  module Install
    class InstallGenerator < ::Rails::Generators::Base
      source_root File.expand_path("templates", __dir__)

      desc "Creates a Hawk Rails initializer file"

      def create_initializer
        template "hawk.rb.tt", "config/initializers/hawk.rb"
      end

      def show_instructions
        say ""
        say "Hawk Rails has been installed!", :green
        say ""
        say "Next steps:"
        say "  1. Set your integration token in config/initializers/hawk.rb"
        say "     or via the HAWK_TOKEN environment variable."
        say "  2. Restart your Rails server."
        say ""
      end
    end
  end
end
