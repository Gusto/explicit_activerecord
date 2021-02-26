# typed: false
# rubocop:disable RSpec/LeakyConstantDeclaration
# rubocop:disable Rails/ApplicationRecord
describe ExplicitActiveRecord::Persistence do # rubocop:disable RSpec/FilePath
  before do
    TestClass.include(ExplicitActiveRecord::Persistence)
    OtherTestClass.include(ExplicitActiveRecord::Persistence)
  end

  after do
    TestClass.dangerous_update_behaviors = []
  end

  describe 'raise' do
    before do
      TestClass.dangerous_update_behaviors = [DeprecationHelper::Strategies::RaiseError.new]
    end

    let(:instance) { TestClass.new }

    context 'an error is thrown after permitting' do
      let(:error_message) { 'ERROR DURING PERMITTED PERSISTENCE' }

      subject do
        TestClass.with_explicit_persistence_for(instance) do
          raise error_message
        end
      end

      it 'revokes the permission' do
        expect(ExplicitActiveRecord::Persistence::PermissionStore).to receive(:revoke).with(instance)
        expect { subject }.to raise_error do |err|
          expect(err.message).to eq(error_message)
        end
      end
    end

    context 'create' do
      context 'when not permitted' do
        it 'raises when attempting to create without permission' do
          current_count = TestClass.count
          expect { instance.save! }.to(raise_error { |error|
            expect(error).to be_a(DeprecationHelper::DeprecationException)
            expect(error.message).to eq('TestClass instances should only be persisted explicitly')
          })
          expect(TestClass.count).to eq current_count
        end
      end

      context 'when permitted' do
        it 'successfully creates the record' do
          TestClass.with_explicit_persistence_for(instance) do
            expect { instance.save! }.to change(TestClass, :count).by(1)
          end
        end
      end

      context 'when override is set' do
        it 'successfully creates the record' do
          instance.instance_variable_set(:@can_be_dangerously_updated, true)
          expect { instance.save! }.to change(TestClass, :count).by(1)
        end
      end
    end

    context 'update/destroy' do
      let(:key) { 'baz' }

      before do
        TestClass.with_explicit_persistence_for(instance) do
          instance.save!
        end
      end

      context 'update' do
        context 'when not permitted' do
          it 'raises when attempting to update' do
            expect { instance.update!(key: key) }.to(raise_error do |error|
              expect(error).to be_a(DeprecationHelper::DeprecationException)
              expect(error.message).to eq('TestClass instances should only be persisted explicitly')
            end)

            TestClass.with_explicit_persistence_for(instance) do
              expect(instance.reload.key).to_not eq(key)
            end
          end
        end

        context 'when permitted' do
          it 'successfully updates the record' do
            TestClass.with_explicit_persistence_for(instance) do
              expect { instance.update!(key: key) }.to change(instance, :key).to(key)
            end
          end
        end

        context 'when override is set' do
          it 'successfully updates the record' do
            instance.instance_variable_set(:@can_be_dangerously_updated, true)
            expect { instance.update!(key: key) }.to change(instance, :key).to(key)
          end
        end
      end

      context 'destroy' do
        context 'when not permitted' do
          it 'raises when attempting to destroy' do
            current_count = TestClass.count
            expect { instance.destroy! }.to(raise_error { |error|
              expect(error).to be_a(DeprecationHelper::DeprecationException)
              expect(error.message).to eq('TestClass instances should only be persisted explicitly')
            })
            expect(TestClass.count).to eq current_count
          end
        end

        context 'when permitted' do
          it 'successfully destroys the record' do
            TestClass.with_explicit_persistence_for(instance) do
              expect { instance.destroy! }.to change(TestClass, :count).by(-1)
            end
          end
        end

        context 'when override is set' do
          it 'successfully destroys the record' do
            instance.instance_variable_set(:@can_be_dangerously_updated, true)
            expect { instance.destroy! }.to change(TestClass, :count).by(-1)
          end
        end
      end
    end
  end

  describe 'noop strategy' do
    before do
      TestClass.dangerous_update_behaviors = []
    end

    let(:instance) { TestClass.new }

    context 'create' do
      context 'when not permitted' do
        it 'does not notify to bugsnag during the create' do
          expect { instance.save! }.to change(TestClass, :count).by(1)
        end
      end

      context 'when permitted' do
        it 'successfully creates the record and does not notify to bugsnag' do
          TestClass.with_explicit_persistence_for(instance) do
            expect { instance.save! }.to change(TestClass, :count).by(1)
          end
        end
      end

      context 'when override is set' do
        it 'successfully creates the record and does not notify to bugsnag' do
          instance.instance_variable_set(:@can_be_dangerously_updated, true)
          expect { instance.save! }.to change(TestClass, :count).by(1)
        end
      end
    end

    context 'update/destroy' do
      let(:key) { 'baz' }

      before do
        TestClass.with_explicit_persistence_for(instance) do
          instance.save!
        end
      end

      context 'update' do
        context 'when not permitted' do
          it 'does not notify to bugsnag during the update' do
            expect { instance.update!(key: key) }.to change(instance, :key).to(key)
          end
        end

        context 'when permitted' do
          it 'successfully updates the record' do
            TestClass.with_explicit_persistence_for(instance) do
              expect { instance.update!(key: key) }.to change(instance, :key).to(key)
            end
          end
        end

        context 'when override is set' do
          it 'successfully updates the record' do
            instance.instance_variable_set(:@can_be_dangerously_updated, true)
            expect { instance.update!(key: key) }.to change(instance, :key).to(key)
          end
        end
      end

      context 'destroy' do
        context 'when not permitted' do
          it 'does not notify to bugsnag during the destroy' do
            expect { instance.destroy! }.to change(TestClass, :count).by(-1)
          end
        end

        context 'when permitted' do
          it 'successfully destroys the record' do
            TestClass.with_explicit_persistence_for(instance) do
              expect { instance.destroy! }.to change(TestClass, :count).by(-1)
            end
          end
        end

        context 'when override is set' do
          it 'successfully destroys the record' do
            instance.instance_variable_set(:@can_be_dangerously_updated, true)
            expect { instance.destroy! }.to change(TestClass, :count).by(-1)
          end
        end
      end
    end
  end

  describe 'with_explicit_persistence_for' do
    before do
      TestClass.dangerous_update_behaviors = [DeprecationHelper::Strategies::RaiseError.new]
    end

    let(:instance) { TestClass.new }
    let(:instance_2) { TestClass.new }
    let(:instance_3) { TestClass.new }

    it 'raise an error if the instance is not if the same class that is extending the concern' do
      expect { OtherTestClass.with_explicit_persistence_for(instance) { instance.save! } }.to raise_error do |error|
        expect(error).to be_a(ExplicitActiveRecord::Persistence::InvalidInstanceOfClassError)
        expect(error.message).to eq('The provided instances of (TestClass) are not an instance of the class (OtherTestClass) extending this concern.')
      end
    end

    it 'raise an error if the instances are not if the same class that is extending the concern' do
      expect { OtherTestClass.with_explicit_persistence_for([instance, instance_2]) { instance.save! } }.to raise_error do |error|
        expect(error).to be_a(ExplicitActiveRecord::Persistence::InvalidInstanceOfClassError)
        expect(error.message).to eq('The provided instances of (TestClass and TestClass) are not an instance of the class (OtherTestClass) extending this concern.')
      end
    end

    context 'create' do
      it "successfully creates the record when wrapping the call within the 'with_explicit_persistence_for' block" do
        expect { TestClass.with_explicit_persistence_for(instance) { instance.save! } }.to change(TestClass, :count).by(1)
      end
    end

    context 'update/destroy' do
      let(:key) { 'baz' }

      before do
        TestClass.with_explicit_persistence_for(instance) do
          instance.save!
        end
      end

      context 'update' do
        it "successfully updates the record when wrapping the call within the 'with_explicit_persistence_for' block" do
          expect { TestClass.with_explicit_persistence_for(instance) { |_| instance.update!(key: key) } }.to change(instance, :key).to(key)
        end
      end

      context 'destroy' do
        it "successfully destroys the record when wrapping the call within the 'with_explicit_persistence_for' block" do
          expect { TestClass.with_explicit_persistence_for(instance) { |_| instance.destroy! } }.to change(TestClass, :count).by(-1)
        end
      end
    end

    context 'multiple instances' do
      it "successfully creates the records when wrapping the call within the 'with_explicit_persistence_for' block" do
        my_model_save = proc do
          TestClass.with_explicit_persistence_for([instance, instance_2, instance_3]) do
            # these are intentionally saved out of order to ensure that they can be saved out of order
            instance_3.save!
            instance.save!
            instance_2.save!
          end
        end
        expect { my_model_save.call }.to change(TestClass, :count).by(3)
      end
    end

    context 'zero instances' do
      it 'executes the block and does not error' do
        block_was_called = false
        TestClass.with_explicit_persistence_for(nil) do
          block_was_called = true
        end
        expect(block_was_called).to eq true
      end
    end

    context 'nested calls for the same model' do
      subject(:persist!) do
        TestClass.with_explicit_persistence_for(instance) do
          TestClass.with_explicit_persistence_for(instance) do
            instance.save!
          end
          instance.save!
        end
      end

      it 'allows the model to be saved for all nested calls' do
        expect { persist! }.not_to raise_error
      end
    end
  end

  describe 'dangerous_update_behaviors' do
    it 'defaults to the global configuration if no behavior is set' do
      global_strategies = [
        DeprecationHelper::Strategies::LogError.new,
      ]
      DeprecationHelper.configure { |config| config.deprecation_strategies = global_strategies }
      expect(OtherTestClass.dangerous_update_behaviors).to eq global_strategies

      configured_behaviors = [DeprecationHelper::Strategies::RaiseError.new]
      OtherTestClass.dangerous_update_behaviors = configured_behaviors

      expect(OtherTestClass.dangerous_update_behaviors).to eq configured_behaviors
    end
  end
end
# rubocop:enable RSpec/LeakyConstantDeclaration
# rubocop:enable Rails/ApplicationRecord
