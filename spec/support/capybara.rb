require "socket"

Capybara.register_driver :selenium_chrome_headless do |app|
  options = Selenium::WebDriver::Chrome::Options.new
  options.add_argument("--headless=new")
  options.add_argument("--no-sandbox")
  options.add_argument("--disable-dev-shm-usage")
  options.add_argument("--disable-gpu")

  # Use chromium binary when google-chrome is not available (Debian/devcontainer)
  options.binary = "/usr/bin/chromium" if File.exist?("/usr/bin/chromium")

  Capybara::Selenium::Driver.new(app, browser: :chrome, options: options)
end

Capybara.javascript_driver = :selenium_chrome_headless

# Bind server to all interfaces so Selenium inside the container can reach it
Capybara.server_host = "0.0.0.0"
Capybara.server_port = 4567

# Point app_host to the container's own IP so Capybara requests go through the network stack
Capybara.app_host = "http://#{IPSocket.getaddress(Socket.gethostname)}:#{Capybara.server_port}"

RSpec.configure do |config|
  config.before(:each, type: :system) do
    driven_by :selenium_chrome_headless
  end
end
