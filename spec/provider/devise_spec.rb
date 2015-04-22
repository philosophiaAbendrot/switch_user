require 'spec_helper'
require 'switch_user/provider/devise'

class FakeWarden
  attr_reader :user_hash

  def initialize
    @user_hash = {}
  end

  def set_user(user, args)
    scope = args.fetch(:scope, :user)
    @user_hash[scope] = user
  end

  def user(scope)
    @user_hash[scope]
  end

  def logout(scope)
    @user_hash.delete(scope)
  end
end

class DeviseController < TestController
  def warden
    @warden ||= FakeWarden.new
  end

  def current_user
    @warder.user
  end
end

describe SwitchUser::Provider::Devise do
  let(:controller) { DeviseController.new }
  let(:provider) { SwitchUser::Provider::Devise.new(controller) }
  let(:user) { double(:user) }
  let(:admin) { double(:admin) }

  it_behaves_like "a provider"

  it 'only allows defined scopes to be used' do
    expect {
      provider.login(user, :foobar)
    }.to raise_error(SwitchUser::Provider::UnknownScopeError)
  end

  it 'can use a default scope' do
    provider.login(user)
    provider.current_user.should == user
  end

  it "can use alternate scopes" do
    allow(SwitchUser).to receive(:available_users).and_return({:user_test => nil, :admin => nil})
    provider.login(admin, :user_test)
    expect(provider.current_user).to eq(admin)
    expect(provider.current_user(:user_test)).to eq(admin)
  end

  describe "#login_inclusive" do

    before do
      allow(SwitchUser).to receive(:available_users).and_return({:user_test => nil, :admin => nil})
      provider.login(admin, :admin)
      provider.login_inclusive(user, :scope => :user_test)
    end

    it 'should log in as the user' do
      expect(provider.current_user).to eq(user)
    end

    it 'should remain logged in as the admin' do
      expect(provider.current_user(:admin)).to eq(admin)
    end

  end

  describe "#login_exclusive" do

    before do
      allow(SwitchUser).to receive(:available_users).and_return({:admin => nil, :user_test => nil})
      provider.login(admin, :admin)
      provider.login_exclusive(user, :scope => "user_test")
    end

    it "logs the user in" do
      expect( provider.current_user ).to eq(user)
    end

    it "logs out other scopes" do
      provider.current_user(:admin).should be_nil
    end
  end

  describe "#logout_all" do
    it "logs out users under all scopes" do
      allow(SwitchUser).to receive(:available_users).and_return({:user => nil, :admin => nil})
      provider.login(user, :admin)
      provider.login(user, :user)

      provider.logout_all

      provider.current_user(:admin).should be_nil
      provider.current_user(:user).should be_nil
    end
  end

  describe "#all_current_users" do
    it "pulls users from an alternate scope" do
      allow(SwitchUser).to receive(:available_users).and_return({:user => nil, :admin => nil})
      provider.login(user, :admin)

      provider.current_users_without_scope.should == [user]
    end
  end
end
