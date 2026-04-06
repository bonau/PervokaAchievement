require 'capybara/rspec'
require 'selenium-webdriver'
require 'fileutils'

SCREENSHOT_DIR = File.join(__dir__, '..', 'screenshots')
FileUtils.mkdir_p(SCREENSHOT_DIR)

Capybara.register_driver :remote_chrome do |app|
  options = Selenium::WebDriver::Chrome::Options.new
  options.add_argument('--no-sandbox')
  options.add_argument('--disable-dev-shm-usage')
  options.add_argument('--window-size=1280,1024')

  Capybara::Selenium::Driver.new(
    app,
    browser: :remote,
    url: ENV.fetch('SELENIUM_URL', 'http://chrome:4444'),
    options: options
  )
end

Capybara.default_driver = :remote_chrome
Capybara.javascript_driver = :remote_chrome
Capybara.app_host = ENV.fetch('REDMINE_URL', 'http://redmine:3000')
Capybara.run_server = false
Capybara.default_max_wait_time = 15

module E2EHelpers
  def take_screenshot(name)
    path = File.join(SCREENSHOT_DIR, "#{name}.png")
    page.save_screenshot(path)
    puts "    Screenshot: #{path}"
    path
  end

  def login_as(username, password)
    visit '/login'
    fill_in 'username', with: username
    fill_in 'password', with: password
    find('input[name="login"]').click
  end
end

RSpec.configure do |config|
  config.include Capybara::DSL
  config.include E2EHelpers

  config.after(:each) do |example|
    if example.exception
      name = example.full_description.gsub(/[^a-zA-Z0-9]/, '_')[0..80]
      take_screenshot("FAIL_#{name}")
    end
  end
end
