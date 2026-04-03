# Hawk Rails

Ruby on Rails catcher for [Hawk](https://hawk.so) error tracker. Captures unhandled exceptions and custom events in Rails 8+ applications and sends them to Hawk.

## Installation

Add to your Gemfile:

```ruby
gem "hawk-rails"
```

Run:

```bash
bundle install
```

Generate the initializer:

```bash
rails generate hawk_rails:install:install
```

This creates `config/initializers/hawk.rb` with all available options.

## Configuration

Set your integration token (get it at [hawk.so](https://hawk.so) → Project Settings → Integrations):

```ruby
# config/initializers/hawk.rb
Hawk::Rails.configure do |config|
  config.token = ENV.fetch("HAWK_TOKEN")
end
```

### All Options

```ruby
Hawk::Rails.configure do |config|
  # Required: integration token
  config.token = ENV.fetch("HAWK_TOKEN")

  # Application release/version (for source maps & suspected commits)
  config.release = ENV.fetch("APP_VERSION", nil)

  # Global context attached to every event
  config.context = { app_name: "MyApp", server: Socket.gethostname }

  # Default user (overridden by per-event user or Warden/Devise auto-detection)
  config.user = { id: "system", name: "Background Worker" }

  # Environments where Hawk is active (default: production, staging)
  config.enabled_environments = %w[production staging]

  # Source code lines to include around each backtrace frame (default: 5)
  config.source_code_lines = 5

  # Send events asynchronously (default: true)
  config.async = true

  # Custom collector endpoint (overrides auto-detected URL from token)
  config.collector_endpoint = "https://custom-collector.example.com/"

  # Filter or modify events before sending (return false to drop)
  config.before_send = ->(event) {
    # Remove sensitive params
    if event.dig(:payload, :context, :request, :params)
      event[:payload][:context][:request][:params].delete(:password)
      event[:payload][:context][:request][:params].delete(:credit_card)
    end
    event
  }
end
```

## Usage

### Automatic Error Catching

Hawk Rails automatically catches all unhandled exceptions via Rack middleware. No extra code needed — just configure your token and deploy.

### Manual Event Sending

```ruby
begin
  risky_operation
rescue => e
  Hawk::Rails.send(e)
end
```

With context:

```ruby
Hawk::Rails.send(error, context: { order_id: order.id, step: "payment" })
```

With user info:

```ruby
Hawk::Rails.send(error, user: { id: current_user.id.to_s, name: current_user.name })
```

### User Detection

Hawk Rails automatically detects the current user via Warden/Devise when available. If no user is found, an anonymous user ID is generated for Affected Users tracking.

You can also set a global default user:

```ruby
Hawk::Rails.configure do |config|
  config.user = { id: "worker-1", name: "Sidekiq Worker" }
end
```

### Sensitive Data Filtering

Use `before_send` to strip sensitive data before it leaves your server:

```ruby
Hawk::Rails.configure do |config|
  config.before_send = ->(event) {
    # Drop all events from a specific error class
    return false if event[:payload][:type] == "ActionController::RoutingError"

    # Remove auth headers
    headers = event.dig(:payload, :context, :request, :headers)
    headers&.delete("Authorization")

    event
  }
end
```

### Event Format

Each event sent to Hawk follows the [Hawk Event Format](https://docs.hawk.so/event-format):

```json
{
  "token": "your-integration-token",
  "catcherType": "errors/ruby",
  "payload": {
    "title": "undefined method `name' for nil:NilClass",
    "type": "NoMethodError",
    "backtrace": [
      {
        "file": "/app/models/user.rb",
        "line": 42,
        "column": 0,
        "function": "full_name",
        "sourceCode": [
          { "line": 40, "content": "  def full_name" },
          { "line": 41, "content": "    first = profile.first_name" },
          { "line": 42, "content": "    last = profile.name" }
        ]
      }
    ],
    "level": 2,
    "release": "v2.1.0",
    "catcherVersion": "0.1.0",
    "context": {
      "request": {
        "url": "https://example.com/users/42",
        "method": "GET",
        "ip": "203.0.113.1"
      }
    },
    "user": { "id": "42", "name": "John Doe" },
    "addons": {
      "rails": { "version": "8.0.0", "environment": "production" },
      "ruby": { "version": "3.3.0", "platform": "x86_64-linux", "engine": "ruby" }
    }
  }
}
```

### Addons

Hawk Rails automatically collects:

- **Rails**: version, environment
- **Ruby**: version, platform, engine

### Error Levels

Error levels are automatically determined:

| Level   | Value | Errors                                           |
|---------|-------|--------------------------------------------------|
| Fatal   | 1     | `SystemExit`, `SignalException`, `NoMemoryError`  |
| Error   | 2     | `RuntimeError`, `StandardError`, and subclasses    |

## Requirements

- Ruby >= 3.2
- Rails >= 8.0

## Development

```bash
bundle install
bundle exec rspec
```

## License

MIT License. See [LICENSE](LICENSE) for details.
