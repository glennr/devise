require 'test/test_helper'
require 'ostruct'

class MockController < ApplicationController
  attr_accessor :env

  def request
    self
  end

  def path
    ''
  end

  def index
  end

  def host_with_port
    "test.host:3000"
  end

  def protocol
    "http"
  end

  def symbolized_path_parameters
    {}
  end
end

class ControllerAuthenticableTest < ActionController::TestCase
  tests MockController

  def setup
    @mock_warden = OpenStruct.new
    @controller.env = { 'warden' => @mock_warden }
  end

  test 'setup warden' do
    assert_not_nil @controller.warden
  end

  test 'provide access to warden instance' do
    assert_equal @controller.warden, @controller.env['warden']
  end

  test 'proxy signed_in? to authenticated' do
    @mock_warden.expects(:authenticate?).with(:scope => :my_scope)
    @controller.signed_in?(:my_scope)
  end

  test 'proxy current_admin to authenticate with admin scope' do
    @mock_warden.expects(:authenticate).with(:scope => :admin)
    @controller.current_admin
  end

  test 'proxy current_user to authenticate with user scope' do
    @mock_warden.expects(:authenticate).with(:scope => :user)
    @controller.current_user
  end

  test 'proxy user_authenticate! to authenticate with user scope' do
    @mock_warden.expects(:authenticate!).with(:scope => :user)
    @controller.authenticate_user!
  end

  test 'proxy admin_authenticate! to authenticate with admin scope' do
    @mock_warden.expects(:authenticate!).with(:scope => :admin)
    @controller.authenticate_admin!
  end

  test 'proxy user_signed_in? to authenticate? with user scope' do
    @mock_warden.expects(:authenticate?).with(:scope => :user)
    @controller.user_signed_in?
  end

  test 'proxy admin_signed_in? to authenticate? with admin scope' do
    @mock_warden.expects(:authenticate?).with(:scope => :admin)
    @controller.admin_signed_in?
  end

  test 'proxy user_session to session scope in warden' do
    @mock_warden.expects(:authenticate).with(:scope => :user).returns(true)
    @mock_warden.expects(:session).with(:user).returns({})
    @controller.user_session
  end

  test 'proxy admin_session to session scope in warden' do
    @mock_warden.expects(:authenticate).with(:scope => :admin).returns(true)
    @mock_warden.expects(:session).with(:admin).returns({})
    @controller.admin_session
  end

  test 'sign in proxy to set_user on warden' do
    user = User.new
    @mock_warden.expects(:set_user).with(user, :scope => :user).returns(true)
    @controller.sign_in(:user, user)
  end

  test 'sign in accepts a resource as argument' do
    user = User.new
    @mock_warden.expects(:set_user).with(user, :scope => :user).returns(true)
    @controller.sign_in(user)
  end

  test 'sign out proxy to logout on warden' do
    @mock_warden.expects(:user).with(:user).returns(true)
    @mock_warden.expects(:logout).with(:user).returns(true)
    @controller.sign_out(:user)
  end

  test 'sign out accepts a resource as argument' do
    @mock_warden.expects(:user).with(:user).returns(true)
    @mock_warden.expects(:logout).with(:user).returns(true)
    @controller.sign_out(User.new)
  end

  test 'stored location for returns the location for a given scope' do
    assert_nil @controller.stored_location_for(:user)
    @controller.session[:"user.return_to"] = "/foo.bar"
    assert_equal "/foo.bar", @controller.stored_location_for(:user)
  end

  test 'stored location for accepts a resource as argument' do
    assert_nil @controller.stored_location_for(:user)
    @controller.session[:"user.return_to"] = "/foo.bar"
    assert_equal "/foo.bar", @controller.stored_location_for(User.new)
  end

  test 'stored location cleans information after reading' do
    @controller.session[:"user.return_to"] = "/foo.bar"
    assert_equal "/foo.bar", @controller.stored_location_for(:user)
    assert_nil @controller.session[:"user.return_to"]
  end

  test 'after sign in path defaults to root path if none by was specified for the given scope' do
    assert_equal root_path, @controller.after_sign_in_path_for(:user)
  end

  test 'after sign in path defaults to the scoped root path' do
    assert_equal admin_root_path, @controller.after_sign_in_path_for(:admin)
  end

  test 'after sign out path defaults to the root path' do
    assert_equal root_path, @controller.after_sign_out_path_for(:admin)
    assert_equal root_path, @controller.after_sign_out_path_for(:user)
  end

  test 'sign in and redirect uses the stored location' do
    user = User.new
    @controller.session[:"user.return_to"] = "/foo.bar"
    @mock_warden.expects(:set_user).with(user, :scope => :user).returns(true)
    @controller.expects(:redirect_to).with("/foo.bar")
    @controller.sign_in_and_redirect(user)
  end

  test 'sign in and redirect uses the configured after sign in path' do
    admin = Admin.new
    @mock_warden.expects(:set_user).with(admin, :scope => :admin).returns(true)
    @controller.expects(:redirect_to).with(admin_root_path)
    @controller.sign_in_and_redirect(admin)
  end

  test 'only redirect if skip is given' do
    admin = Admin.new
    @controller.expects(:redirect_to).with(admin_root_path)
    @controller.sign_in_and_redirect(:admin, admin, true)
  end

  test 'sign out and redirect uses the configured after sign out path' do
    @mock_warden.expects(:user).with(:admin).returns(true)
    @mock_warden.expects(:logout).with(:admin).returns(true)
    @controller.expects(:redirect_to).with(admin_root_path)
    @controller.instance_eval "def after_sign_out_path_for(resource); admin_root_path; end"
    @controller.sign_out_and_redirect(:admin)
  end

  test 'is not a devise controller' do
    assert_not @controller.devise_controller?
  end

  test 'default url options are retrieved from devise' do
    begin
      Devise.default_url_options {{ :locale => I18n.locale }}
      assert_equal({ :locale => :en }, @controller.send(:default_url_options))
    ensure
      Devise.default_url_options {{ }}
    end
  end
end
