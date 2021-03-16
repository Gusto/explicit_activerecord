# typed: ignore

module ExplicitActiveRecord
  describe NoDBAccess do
    include NoDBAccess

    describe '#no_db_access' do
      it 'allows saving' do
        TestModel.create! name: 'george'
        test_model = TestModel.first
        test_model.name = 'bob'
        test_model.save!
      end

      it 'prevents raw sql' do
        TestModel.create! name: 'george'
        expect do
          no_db_access do
            TestModel.connection.execute('select * from test_models')
          end
        end.to raise_error NoDBAccess::DbAccessError
      end

      it 'prevents finding even when no record are returned' do
        expect do
          no_db_access do
            TestModel.first
          end
        end.to raise_error NoDBAccess::DbAccessError
      end

      it 'prevents plucking in a pure function' do
        TestModel.create! name: 'george'
        expect do
          no_db_access do
            expect(TestModel.pluck(:name)).to eq(['george'])
          end
        end.to raise_error NoDBAccess::DbAccessError
      end

      it 'prevents dynamic finds in a pure function' do
        TestModel.create! name: 'george'
        expect do
          no_db_access do
            expect(TestModel.find_by_name('george')).to eq TestModel.first
          end
        end.to raise_error NoDBAccess::DbAccessError
      end

      it 'prevents joins in a pure function' do
        test_model = TestModel.create!
        5.times { OtherTestModel.create!(test_model_id: test_model.id) }
        expect do
          no_db_access do
            expect(TestModel.joins(:other_test_models).uniq).to eq([TestModel.first])
          end
        end.to raise_error NoDBAccess::DbAccessError
      end

      it 'prevents finding in a pure function' do
        TestModel.create! name: 'george'
        expect do
          no_db_access do
            TestModel.first
          end
        end.to raise_error NoDBAccess::DbAccessError
      end

      it 'prevents saving in a pure function' do
        test_model = TestModel.create! name: 'george'
        puts 'point 1'
        no_db_access do
          test_model.name = 'bob'
        end
        expect do
          puts 'point 2'
          no_db_access do
            test_model.save!
          end
        end.to raise_error NoDBAccess::DbAccessError
      end

      it 'prevents creating in a pure function' do
        expect do
          no_db_access do
            TestModel.create! name: 'stuff'
          end
        end.to raise_error NoDBAccess::DbAccessError
      end

      it 'prevents destroying in a pure function' do
        test_model = TestModel.create! name: 'stuff'
        expect do
          no_db_access do
            test_model.destroy
          end
        end.to raise_error NoDBAccess::DbAccessError
      end

      it 'be able to next pure_functions' do
        expect(NoDBAccess.in_a_no_db_access_block?).to be(false)
        no_db_access do
          expect(NoDBAccess.in_a_no_db_access_block?).to be(true)
          no_db_access do
            expect(NoDBAccess.in_a_no_db_access_block?).to be(true)
          end
          expect(NoDBAccess.in_a_no_db_access_block?).to be(true)
        end
        expect(NoDBAccess.in_a_no_db_access_block?).to be(false)
      end
    end
  end
end
