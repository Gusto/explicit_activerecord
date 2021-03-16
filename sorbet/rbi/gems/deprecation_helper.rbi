# This file is autogenerated. Do not edit it by hand. Regenerate it with:
#   srb rbi gems

# typed: strict
#
# If you would like to make changes to this file, great! Please create the gem's shim here:
#
#   https://github.com/sorbet/sorbet-typed/new/master?filename=lib/deprecation_helper/all/deprecation_helper.rbi
#
# deprecation_helper-0.1.0

module DeprecationHelper
  def self.config(*args, &blk); end
  def self.configure(*args, &blk); end
  def self.deprecate!(*args, &blk); end
  def self.deprecation_strategies(*args, &blk); end
  extend T::Private::Methods::MethodHooks
  extend T::Private::Methods::SingletonMethodHooks
  extend T::Sig
end
module DeprecationHelper::Private
end
class DeprecationHelper::Private::Configuration
  def deprecation_strategies(*args, &blk); end
  def deprecation_strategies=(*args, &blk); end
  def initialize(*args, &blk); end
  extend T::Private::Methods::MethodHooks
  extend T::Private::Methods::SingletonMethodHooks
  extend T::Sig
end
class DeprecationHelper::Private::AllowList
  def self.allowed?(*args, &blk); end
  extend T::Private::Methods::MethodHooks
  extend T::Private::Methods::SingletonMethodHooks
  extend T::Sig
end
module DeprecationHelper::Strategies
end
module DeprecationHelper::Strategies::BaseStrategyInterface
  def apply!(*args, &blk); end
  extend T::Helpers
  extend T::InterfaceWrapper::Helpers
  extend T::Private::Abstract::Hooks
  extend T::Private::Methods::MethodHooks
  extend T::Private::Methods::SingletonMethodHooks
  extend T::Sig
end
module DeprecationHelper::Strategies::ErrorStrategyInterface
  def apply!(*args, &blk); end
  def apply_to_exception!(*args, &blk); end
  extend T::Helpers
  extend T::InterfaceWrapper::Helpers
  extend T::Private::Abstract::Hooks
  extend T::Private::Methods::MethodHooks
  extend T::Private::Methods::SingletonMethodHooks
  extend T::Sig
  include DeprecationHelper::Strategies::BaseStrategyInterface
end
class DeprecationHelper::Strategies::RaiseError
  def apply!(*args, &blk); end
  extend T::Private::Methods::MethodHooks
  extend T::Private::Methods::SingletonMethodHooks
  extend T::Sig
  include DeprecationHelper::Strategies::BaseStrategyInterface
end
class DeprecationHelper::Strategies::LogError
  def apply!(*args, &blk); end
  def initialize(*args, &blk); end
  extend T::Private::Methods::MethodHooks
  extend T::Private::Methods::SingletonMethodHooks
  extend T::Sig
  include DeprecationHelper::Strategies::BaseStrategyInterface
end
class DeprecationHelper::DeprecationException < StandardError
  def initialize(*args, &blk); end
  extend T::Private::Methods::MethodHooks
  extend T::Private::Methods::SingletonMethodHooks
  extend T::Sig
end
