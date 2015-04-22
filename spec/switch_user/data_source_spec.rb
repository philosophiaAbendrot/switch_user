
require 'active_record'
require 'switch_user/data_source'

module SwitchUser
  describe DataSource do
    describe '#users' do
      it "can load users" do
        loader = lambda { [ double, double] }
        source = DataSource.new(loader, :user, :id, :email)
        source.users.should have(2).records
      end
    end
    describe '#find_by_id' do
      it 'can use an ActiveRecord::Base strategy to retrieve an object' do
        fake_active_record_model_class = double(:fake_active_record_model_class)
        expect(fake_active_record_model_class).to receive(:kind_of?).with(ActiveRecord::Base).and_return(true)
        loader = lambda { fake_active_record_model_class }
        source = DataSource.new(loader, :user, :id, :email)
        expect(fake_active_record_model_class).to receive(:where).with(:id => 10).and_return([])

        source.find_by_id(10)
      end
    end
  end

  describe DataSources do
    it "aggregates multiple data_sources" do
      user = double(:user)
      s1 = double(:s1, :users => [user])
      source = DataSources.new([s1,s1])

      source.users.should == [user, user]
    end

    describe "#find_source_id" do
      it "can find a corresponding record across data sources" do
        user = double(:user, :scope_id => "user_10")
        s1 = double(:s1, :users => [])
        s2 = double(:s1, :users => [user])
        source = DataSources.new([s1,s2])

        source.find_scope_id("user_10").should == user
      end

      #Below is an optimization for activerecord
      it 'Should use a DataSource find_by_id method when available' do
        s1 = double(:s1, :scope => "user", :users => [])
        source = DataSources.new([s1])
        expect(s1).to receive(:find_by_id).with('10')
        source.find_scope_id("user_10")
      end

    end

  end

  describe Record do
    it "can be compared to a identifier string" do
      id1 = "user_100"
      id2 = "user_101"
      id3 = "staff_100"
      user = double(:user, :id => 100, :email => "test@example.com")
      source = DataSource.new(nil, :user, :id, :email)

      record = Record.new(user, source)

      record.should be_equivalent(id1)
      record.should_not be_equivalent(id2)
      record.should_not be_equivalent(id3)
    end
  end
end
