# Load Redmine test environment
require File.expand_path('../../../../config/environment', __FILE__)

require 'rspec/rails'

# Eagerly load all application constants so Zeitwerk does not perform
# lazy loading during test execution. Lazy loading can cause Zeitwerk's
# internal mutex (@lock) to be in an incomplete state when RSpec tries
# to set up message expectations on achievement classes, resulting in
# NoMethodError: undefined method 'synchronize' for #<Module:...>.
Rails.application.eager_load!

# Explicitly apply plugin patches in the test environment.
# Rails.configuration.to_prepare may not fire before RSpec loads depending
# on the Redmine/Rails version; applying here guarantees correct state.
[
  [User,       PervokaAchievement::Patches::UserPatch],
  [Issue,      PervokaAchievement::Patches::IssuePatch],
  [Mailer,     PervokaAchievement::Patches::MailerPatch],
  [Project,    PervokaAchievement::Patches::ProjectPatch],
  [Attachment, PervokaAchievement::Patches::AttachmentPatch],
].each do |klass, patch|
  klass.send(:include, patch) unless klass.included_modules.include?(patch)
end

# Load Redmine test fixtures path
REDMINE_TEST_DIR = File.expand_path('../../../../test', __FILE__)

RSpec.configure do |config|
  if config.respond_to?(:fixture_paths=)
    config.fixture_paths = ["#{REDMINE_TEST_DIR}/fixtures"]
  else
    config.fixture_path = "#{REDMINE_TEST_DIR}/fixtures"
  end
  config.use_transactional_fixtures = true
  config.infer_spec_type_from_file_location!

  config.expect_with :rspec do |expectations|
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end

  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end

  config.shared_context_metadata_behavior = :apply_to_host_groups
  config.order = :random
  Kernel.srand config.seed
end
