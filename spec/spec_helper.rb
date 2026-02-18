# Load Redmine test environment
require File.expand_path('../../../../config/environment', __FILE__)

require 'rspec/rails'

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
