require 'bundler/setup'
require 'explicit_activerecord'
require 'sqlite3'
require 'active_record'
require 'pry'

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = '.rspec_status'

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end

  config.expose_dsl_globally = true

  config.before do
    DeprecationHelper.configure do |helper_config|
      helper_config.deprecation_strategies = [
        DeprecationHelper::Strategies::LogError.new,
        DeprecationHelper::Strategies::RaiseError.new,
      ]
    end
  end
end

ActiveRecord::Base.establish_connection(
  :adapter => 'sqlite3',
  :database => ':memory:',
)

ActiveRecord::Schema.define do
  create_table :my_explicit_active_record_test_classes do |table|
    table.string :key
  end

  create_table :my_other_explicit_active_record_test_classes do |table|
  end

  create_table :my_unconfigured_explicit_active_record_test_classes do |table|
  end

  create_table :foos do |table|
    table.string :name
  end
end

T::Configuration.call_validation_error_handler = ->(signature, opts) {
  # Do nothing if type signatures fail in test
}
