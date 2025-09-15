lib = File.expand_path('lib', __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

Gem::Specification.new do |spec|
  spec.name          = 'explicit_activerecord'
  spec.version       = '0.2.0'
  spec.authors       = ['Alex Evanczuk']
  spec.email         = ['alex.evanczuk@gusto.com']

  spec.summary       = 'This is a gem for using ActiveRecord more explicitly.'
  spec.homepage      = 'https://github.com/Gusto/explicit_activerecord'
  spec.license       = 'MIT'

  spec.required_ruby_version = '>= 3.0'

  # Specify which files should be added to the gem when it is released.
  spec.files         = Dir["LICENSE", "README.md", "lib/**/*"]

  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_dependency 'sorbet-runtime', '>= 0.5.6293'

  # This dependency powers the behavior for ExplicitActiveRecord
  spec.add_dependency 'deprecation_helper'

  # This gem is specifically an ActiveSupport::Concern for ActiveRecord::Base models
  spec.add_dependency 'activerecord'
  spec.add_dependency 'activesupport'

  spec.add_development_dependency 'pry'
  spec.add_development_dependency 'rspec', '~> 3.0'
  spec.add_development_dependency 'sorbet'
  # This allows us to test ActiveRecord business logic without needing an underlying database:
  spec.add_development_dependency 'sqlite3'
  spec.add_development_dependency 'tapioca'
end
