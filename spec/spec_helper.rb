require 'bundler/setup'
require 'explicit_activerecord'
require 'sqlite3'
require 'active_record'
require 'pry'

# This allows each test to have reference to the test class without test pollution
def define_test_models(config)
  config.before(:each) do
    # https://makandracards.com/makandra/47189-rspec-how-to-define-classes-for-specs
    test_model = Class.new(ActiveRecord::Base) do
      has_many :other_test_models
    end

    other_test_model = Class.new(ActiveRecord::Base)

    stub_const('TestModel', test_model)
    stub_const('OtherTestModel', other_test_model)
  end
end

def setup_database
  ActiveRecord::Base.establish_connection(
    :adapter => 'sqlite3',
    :database => ':memory:',
  )

  ActiveRecord::Schema.define do
    create_table :test_models do |table|
      table.string :key
      table.string :name
    end

    create_table :other_test_models do |table|
      table.string :name
      table.references :test_model
    end
  end
end

def make_sorbet_signatures_noop
  T::Configuration.call_validation_error_handler = ->(signature, opts) {
    # Do nothing if type signatures fail in test
  }
end

def setup_global_deprecation_helper_behavior(config)
  config.before do
    DeprecationHelper.configure do |helper_config|
      helper_config.deprecation_strategies = [
        DeprecationHelper::Strategies::LogError.new,
        DeprecationHelper::Strategies::RaiseError.new,
      ]
    end
  end
end

def teardown_database(config)
  config.after do
    ActiveRecord::Base.connection.execute('delete from test_models')
    ActiveRecord::Base.connection.execute('delete from other_test_models')
  end
end

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

  setup_global_deprecation_helper_behavior(config)
  define_test_models(config)
  setup_database
  make_sorbet_signatures_noop
  teardown_database(config)
end

