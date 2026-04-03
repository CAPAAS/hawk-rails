# Changelog

## [0.1.0] - 2026-04-03

### Added

- Initial release of hawk-rails gem
- Automatic exception catching via Rack middleware
- Manual event sending via `Hawk::Rails.send`
- Backtrace parsing with source code context
- Request info capture (URL, method, headers, params, IP)
- User auto-detection via Warden/Devise
- Anonymous user ID generation for affected users tracking
- Global and per-event context support
- `before_send` hook for event filtering and sensitive data removal
- Error level detection (fatal/error)
- Rails and Ruby addons (version, environment, platform)
- Async event delivery (configurable)
- Custom collector endpoint support
- Rails generator for initializer setup (`rails g hawk_rails:install:install`)
- Configurable source code context lines
- Environment-based activation (default: production, staging)
