module CookieHelpers
  # Rack::Test::CookieJar (used in request specs) doesn't expose
  # `signed` / `encrypted` views like ActionDispatch's CookieJar.
  # This helper rebuilds a real ActionDispatch jar from the current
  # response so specs can read signed cookies set by the controller.
  def signed_cookies
    jar = ActionDispatch::Cookies::CookieJar.build(request, cookies.to_hash)
    jar.signed
  end

  # Wrapper so existing test patterns like `cookies.signed[:foo]` work.
  # Returns a small object with a `.signed` method delegating to the
  # rebuilt jar, while still allowing direct `cookies[:foo]` access.
  def cookies
    SignedAwareCookieJar.new(super, -> { request })
  end

  class SignedAwareCookieJar
    def initialize(jar, request_proc)
      @jar = jar
      @request_proc = request_proc
    end

    def signed
      ActionDispatch::Cookies::CookieJar.build(@request_proc.call, @jar.to_hash).signed
    end

    def method_missing(name, *args, &block)
      @jar.public_send(name, *args, &block)
    end

    def respond_to_missing?(name, include_private = false)
      @jar.respond_to?(name, include_private) || super
    end

    def [](key)
      @jar[key]
    end

    def []=(key, value)
      @jar[key] = value
    end
  end
end

RSpec.configure do |config|
  config.include CookieHelpers, type: :request
end
