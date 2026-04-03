# frozen_string_literal: true

require_relative "lib/hawk/rails/version"

Gem::Specification.new do |spec|
  spec.name          = "hawk-rails"
  spec.version       = Hawk::Rails::VERSION
  spec.authors       = ["Alexander Panasenkov"]
  spec.email         = ["apanasenkov@capaa.ru"]

  spec.summary       = "Hawk error tracker catcher for Ruby on Rails"
  spec.description   = "Captures unhandled exceptions and custom events in Rails 8+ applications and sends them to Hawk (hawk.so) error tracker."
  spec.homepage      = "https://github.com/capaas/hawk-rails"
  spec.license       = "MIT"

  spec.required_ruby_version = ">= 3.2"

  spec.metadata["homepage_uri"]    = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage
  spec.metadata["changelog_uri"]   = "#{spec.homepage}/blob/main/CHANGELOG.md"

  spec.files = Dir.chdir(__dir__) do
    `git ls-files -z`.split("\x0").reject do |f|
      (File.expand_path(f) == __FILE__) ||
        f.start_with?("spec/", ".git", ".github", "bin/")
    end
  end

  spec.require_paths = ["lib"]

  spec.add_dependency "railties", "~> 8.0"
  spec.add_dependency "net-http", "~> 0.4"

  spec.add_development_dependency "rspec", "~> 3.0"
  spec.add_development_dependency "webmock", "~> 3.0"
  spec.add_development_dependency "rake", "~> 13.0"
  spec.add_development_dependency "rubocop", "~> 1.0"
  spec.add_development_dependency "actionpack", "~> 8.0"
end
