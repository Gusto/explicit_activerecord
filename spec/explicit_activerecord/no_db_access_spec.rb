# typed: false
class ApplicationRecord < ActiveRecord::Base
  self.abstract_class = true
end

class Foo < ApplicationRecord
end

module ExplicitActiveRecord
  describe NoDBAccess do
    include NoDBAccess

    after do
      Foo.delete_all
    end

    describe '#no_db_access' do
      it 'allows saving' do
        Foo.create! name: 'george'
        foo = Foo.first
        foo.name = 'bob'
        foo.save!
      end

      it 'prevents raw sql' do
        Foo.create! name: 'george'
        expect do
          no_db_access do
            Foo.connection.execute('select * from foos')
          end
        end.to raise_error NoDBAccess::DbAccessError
      end

      it 'prevents finding even when no record are returned' do
        expect do
          no_db_access do
            Foo.first
          end
        end.to raise_error NoDBAccess::DbAccessError
      end

      it 'prevents plucking in a pure function' do
        Foo.create! name: 'george'
        expect do
          no_db_access do
            expect(Foo.pluck(:name)).to eq(['george'])
          end
        end.to raise_error NoDBAccess::DbAccessError
      end

      it 'prevents finding in a pure function' do
        Foo.create! name: 'george'
        expect do
          no_db_access do
            Foo.first
          end
        end.to raise_error NoDBAccess::DbAccessError
      end

      it 'prevents saving in a pure function' do
        foo = Foo.create! name: 'george'
        puts 'point 1'
        no_db_access do
          foo.name = 'bob'
        end
        expect do
          puts 'point 2'
          no_db_access do
            foo.save!
          end
        end.to raise_error NoDBAccess::DbAccessError
      end

      it 'prevents creating in a pure function' do
        expect do
          no_db_access do
            Foo.create! name: 'stuff'
          end
        end.to raise_error NoDBAccess::DbAccessError
      end

      it 'prevents destroying in a pure function' do
        foo = Foo.create! name: 'stuff'
        expect do
          no_db_access do
            foo.destroy
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
