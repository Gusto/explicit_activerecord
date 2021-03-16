# typed: true

# this is meant to allow callers to write code like this:
#   model = MyModel.find
#   no_db_access do
#     (do things with model...)
#   end
#   model.save!
# you are guaranteed that no database access will happen within the no_db_access block
module ExplicitActiveRecord
  module NoDBAccess
    extend T::Sig

    sig { returns(T::Boolean) }
    def self.in_a_no_db_access_block?
      (@pure_function_block_counter || 0) > 0
    end

    sig { void }
    def self.no_db_access
      unless @subscribed
        ActiveSupport::Notifications.subscribe('sql.active_record') do |_name, _start, _finish, _id, _payload|
          if NoDBAccess.in_a_no_db_access_block?
            @should_raise = true
          end
        end
        @subscribed = true
      end

      @pure_function_block_counter = (@pure_function_block_counter || 0) + 1
      yield

      if @should_raise
        @should_raise = false
        raise DbAccessError.new('Cannot execute sql within a no_db_access block.')
      end
    ensure
      @should_raise = false
      @pure_function_block_counter -= 1
    end

    sig { params(block: T.proc.void).void }
    def no_db_access(&block)
      NoDBAccess.no_db_access(&block)
    end

    class DbAccessError < StandardError; end
  end
end
