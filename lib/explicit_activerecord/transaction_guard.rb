# typed: true

# prevent callers from calling your methods within a transaction,
# providing you with confidence that you can perform non-atomic operations, or mutate records without something downstream triggering a rollback,
#
# class MyService
#   include ExplicitActiveRecord::TransactionGuard
#
#   def my_non_atomic_method(args)
#     ensure_transaction_integrity!
#     SidekiqWorker.perform_async(args)
#   end
#
#   private
#
#   def trust_me_im_not_in_a_transaction(args)
#     allow_transaction do
#       my_non_atomic_method(args)
#     end
#   end
# end

module ExplicitActiveRecord
  module TransactionGuard
    extend T::Sig

    class ForbiddenCallWhileInDbTransaction < StandardError; end

    class << self
      extend T::Sig

      sig { returns(T.nilable(Integer)) }
      attr_accessor :allowed_transaction_count

      sig { returns(T.nilable(T::Boolean)) }
      attr_accessor :ignore

      sig { returns(Integer) }
      def open_transactions
        ActiveRecord::Base.connection.open_transactions
      end

      sig { returns(Integer) }
      def excessive_transactions
        open_transactions - (allowed_transaction_count || 0)
      end
    end

    sig { void }
    def ensure_transaction_integrity!
      unless TransactionGuard.ignore == true || TransactionGuard.excessive_transactions <= 0
        Kernel.raise ForbiddenCallWhileInDbTransaction, "This method guards against open transactions. You have called it with #{TransactionGuard.excessive_transactions} open tranactions."
      end
    end

    sig { params(blk: T.proc.returns(T.untyped)).returns(T.untyped) }
    def ignore_transaction_integrity!(&blk)
      TransactionGuard.ignore = true
      yield
    ensure
      TransactionGuard.ignore = false
    end

    sig { params(blk: T.proc.returns(T.untyped)).returns(T.untyped) }
    def allow_transaction(&blk)
      TransactionGuard.allowed_transaction_count ||= 0
      TransactionGuard.allowed_transaction_count = T.must(TransactionGuard.allowed_transaction_count) + 1
      yield
    ensure
      TransactionGuard.allowed_transaction_count = T.must(TransactionGuard.allowed_transaction_count) - 1
    end
  end
end

