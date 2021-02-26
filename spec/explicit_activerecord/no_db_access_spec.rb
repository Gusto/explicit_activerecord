# typed: false

module ExplicitActiveRecord
  describe NoDBAccess do
    include NoDBAccess

    describe '#no_db_access' do
      it 'allows saving' do
        TestClass.create! name: 'george'
        test_class = TestClass.first
        test_class.name = 'bob'
        test_class.save!
      end

      it 'prevents raw sql' do
        TestClass.create! name: 'george'
        expect do
          no_db_access do
            TestClass.connection.execute('select * from test_classes')
          end
        end.to raise_error NoDBAccess::DbAccessError
      end

      it 'prevents finding even when no record are returned' do
        expect do
          no_db_access do
            TestClass.first
          end
        end.to raise_error NoDBAccess::DbAccessError
      end

      it 'prevents plucking in a pure function' do
        TestClass.create! name: 'george'
        expect do
          no_db_access do
            expect(TestClass.pluck(:name)).to eq(['george'])
          end
        end.to raise_error NoDBAccess::DbAccessError
      end

      it 'prevents dynamic finds in a pure function' do
        TestClass.create! name: 'george'
        expect do
          no_db_access do
            expect(TestClass.find_by_name('george')).to eq TestClass.first
          end
        end.to raise_error NoDBAccess::DbAccessError
      end

      it 'prevents joins in a pure function' do
        test_class = TestClass.create!
        5.times { OtherTestClass.create!(test_class_id: test_class.id) }
        expect do
          no_db_access do
            expect(TestClass.joins(:other_test_classes).uniq).to eq([TestClass.first])
          end
        end.to raise_error NoDBAccess::DbAccessError
      end

      it 'prevents finding in a pure function' do
        TestClass.create! name: 'george'
        expect do
          no_db_access do
            TestClass.first
          end
        end.to raise_error NoDBAccess::DbAccessError
      end

      it 'prevents saving in a pure function' do
        test_class = TestClass.create! name: 'george'
        puts 'point 1'
        no_db_access do
          test_class.name = 'bob'
        end
        expect do
          puts 'point 2'
          no_db_access do
            test_class.save!
          end
        end.to raise_error NoDBAccess::DbAccessError
      end

      it 'prevents creating in a pure function' do
        expect do
          no_db_access do
            TestClass.create! name: 'stuff'
          end
        end.to raise_error NoDBAccess::DbAccessError
      end

      it 'prevents destroying in a pure function' do
        test_class = TestClass.create! name: 'stuff'
        expect do
          no_db_access do
            test_class.destroy
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
