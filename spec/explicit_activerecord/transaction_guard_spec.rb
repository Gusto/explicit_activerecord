# typed: ignore

module ExplicitActiveRecord
  describe TransactionGuard do
    include TransactionGuard

    describe '#ensure_transaction_integrity!' do
      subject(:with_transaction_integrity) { ensure_transaction_integrity!; true }

      context 'when called while not in a transaction' do
        it { is_expected.to be true }
      end

      context 'when called within a transaction' do
        subject(:with_transaction) do
          TestModel.transaction(requires_new: true, joinable: false) do
            with_transaction_integrity
          end
        end

        it 'raises ForbiddenCallWhileInDbTransaction' do
          expect { subject }.to raise_error TransactionGuard::ForbiddenCallWhileInDbTransaction
        end

        describe '#ignore_transaction_integrity!' do
          subject do
            ignore_transaction_integrity! do
              with_transaction
            end
          end

          it { is_expected.to be true }
        end

        describe '#allow_transaction' do
          subject(:with_single_transaction_allowed) do
            allow_transaction { with_transaction }
          end

          it { is_expected.to be true }

          context 'but it is called within two transactions' do
            subject do
              TestModel.transaction(requires_new: true, joinable: false) do
                with_single_transaction_allowed
              end
            end

            it 'raises ForbiddenCallWhileInDbTransaction' do
              expect { subject }.to raise_error TransactionGuard::ForbiddenCallWhileInDbTransaction
            end
          end
        end
      end
    end
  end
end
