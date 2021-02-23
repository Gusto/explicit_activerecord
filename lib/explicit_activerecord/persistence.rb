# typed: false

require 'sorbet-runtime'
require 'active_support/concern'
require 'deprecation_helper'

module ExplicitActiveRecord
  module Persistence
    extend T::Sig

    extend ActiveSupport::Concern

    class UnrecognizedDangerousUpdateResponseBehaviorError < StandardError
      extend T::Sig

      sig { void }
      def initialize
        super 'Please provide a behavior that implements DeprecationHelper::Strategies::StrategyBase'
      end
    end

    class InvalidInstanceOfClassError < ArgumentError
      extend T::Sig

      sig { params(klass: T.class_of(ActiveRecord::Base), instances: T::Array[ActiveRecord::Base]).void }
      def initialize(klass, instances)
        super "The provided instances of (#{instances.map(&:class).to_sentence}) are not an instance of the class (#{klass}) extending this concern."
      end
    end

    included do |base|
      extend T::Sig

      before_save :ensure_explicitly_persisted!
      before_destroy :ensure_explicitly_persisted!

      base.class_eval do
        sig { params(behaviors: T::Array[DeprecationHelper::Strategies::BaseStrategyInterface]).returns(T::Boolean) }
        def self.dangerous_update_behaviors=(behaviors)
          if behaviors.all? { |behavior| behavior.is_a?(DeprecationHelper::Strategies::BaseStrategyInterface) }
            @dangerous_update_behaviors = behaviors
            true
          else
            raise UnrecognizedDangerousUpdateResponseBehaviorError
          end
        end

        sig { returns(T::Array[DeprecationHelper::Strategies::BaseStrategyInterface]) }
        def self.dangerous_update_behaviors
          # By default, `ExplicitActiveRecord` uses whatever the global configuration is for DeprecationHelper.
          @dangerous_update_behaviors || DeprecationHelper.deprecation_strategies
        end
      end

      sig { params(instance_or_instances: T.nilable(T.any(ActiveRecord::Base, T::Array[ActiveRecord::Base]))).returns(T.untyped) }
      def self.with_explicit_persistence_for(instance_or_instances)
        if instance_or_instances.present?
          instances = Array.wrap(instance_or_instances)

          invalid_instances = instances.select { |i| i.class != self }
          if invalid_instances.any?
            raise InvalidInstanceOfClassError.new(self, invalid_instances)
          end

          begin
            instances.each { |model| PermissionStore.permit(model) }
            ret = yield
          ensure
            instances.each { |model| PermissionStore.revoke(model) }
          end

          ret
        else
          yield
        end
      end

      sig { returns(T.untyped) }
      def can_be_dangerously_updated
        @can_be_dangerously_updated
      end

      private

      sig { returns(T.untyped) }
      def ensure_explicitly_persisted!
        return true if PermissionStore.permitted?(self)

        DeprecationHelper.deprecate!(
          "#{self.class.name} instances should only be persisted explicitly",
          allow_list: ['bin/rails'],
          deprecation_strategies: self.class.dangerous_update_behaviors,
        )

        true
      end
    end

    # Note that this should probably be a `private_constant :PermissionStore`
    # However, some clients are stubbing the methods here because the want to stub
    # ExplicitActiveRecord in spec.
    #
    # TODO: Give a supported API for stubbing explicit persistence and then make this a private constant.
    #
    class PermissionStore
      extend T::Sig

      sig { params(model: ActiveRecord::Base).returns(Array) }
      def self.permit(model)
        self.storage.push(model)
      end

      sig { params(model: ActiveRecord::Base).returns(T.untyped) }
      def self.revoke(model)
        idx = self.storage.index(model)
        self.storage.delete_at(idx) unless idx.nil?
      end

      sig { params(model: ActiveRecord::Base).returns(T::Boolean) }
      def self.permitted?(model)
        model.can_be_dangerously_updated || self.storage.include?(model)
      end

      sig { returns(Array) }
      def self.storage
        @storage ||= []
      end

      # don't need to construct this class, directly
      private_class_method :new
    end
  end
end
