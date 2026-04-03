# frozen_string_literal: true

RSpec.describe Hawk::Rails::Middleware do
  let(:token) { build_token(integration_id: "test-id") }
  let(:app) { ->(env) { [200, {}, ["OK"]] } }
  let(:middleware) { described_class.new(app) }

  before do
    Hawk::Rails.configure do |config|
      config.token = token
      config.enabled_environments = [::Rails.env.to_s]
      config.async = false
    end
  end

  it "passes through successful requests" do
    env = Rack::MockRequest.env_for("/test")
    status, _headers, _body = middleware.call(env)

    expect(status).to eq(200)
  end

  it "catches and re-raises exceptions" do
    error = RuntimeError.new("middleware test error")
    error_app = ->(_env) { raise error }
    error_middleware = described_class.new(error_app)

    stub_request(:post, "https://test-id.k1.hawk.so/")
      .to_return(status: 200)

    env = Rack::MockRequest.env_for("/test", method: "GET")

    expect { error_middleware.call(env) }.to raise_error(RuntimeError, "middleware test error")
  end

  it "sends error event to Hawk when exception occurs" do
    error = RuntimeError.new("should be sent")
    error_app = ->(_env) { raise error }
    error_middleware = described_class.new(error_app)

    stub = stub_request(:post, "https://test-id.k1.hawk.so/")
      .to_return(status: 200)

    env = Rack::MockRequest.env_for("/api/users", method: "POST")

    expect { error_middleware.call(env) }.to raise_error(RuntimeError)
    expect(stub).to have_been_requested
  end

  it "includes request info in the event" do
    error = RuntimeError.new("request info test")
    error_app = ->(_env) { raise error }
    error_middleware = described_class.new(error_app)

    stub = stub_request(:post, "https://test-id.k1.hawk.so/")
      .to_return(status: 200)

    env = Rack::MockRequest.env_for(
      "https://example.com/api/users?page=1",
      method: "GET",
      "HTTP_ACCEPT" => "application/json"
    )

    expect { error_middleware.call(env) }.to raise_error(RuntimeError)

    body = JSON.parse(WebMock::RequestRegistry.instance.requested_signatures.hash.keys.first.body)
    context = body["payload"]["context"]
    expect(context["request"]["method"]).to eq("GET")
    expect(context["request"]["url"]).to include("/api/users")
  end
end
