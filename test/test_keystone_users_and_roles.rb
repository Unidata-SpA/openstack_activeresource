test_path = File.expand_path('..', __FILE__)
$:.unshift(test_path)

require 'helper'

class TestOpenStackActiveResource < Test::Unit::TestCase
  include OpenstackTestUtils

  USER_NAME="__test_user__"

  def test_10_user_create
    return unless admin_test_possible?

    auth_admin

    tenant = OpenStack::Keystone::Admin::Tenant.find(TEST_CONFIG[:user_tenant_id])
    assert_not_nil tenant, "Cannot retrieve tenant"

    assert_nothing_raised ActiveResource::ClientError, "Cannot create user" do
      new_user = OpenStack::Keystone::Admin::User.create :name => USER_NAME,
                                                         :password => "test_password_123",
                                                         :email => "fake@pretend.test",
                                                         :enabled => false,
                                                         :tenant => tenant

      assert_not_nil new_user.id, "Cannot create user: #{active_resource_errors_to_s(new_user)}"
    end

  end

  def test_20_user_list
    return unless admin_test_possible?

    auth_admin

    assert_nothing_raised ActiveResource::ClientError, "Cannot list users" do
      users = OpenStack::Keystone::Admin::User.all

      assert_block("No users?") do
        !users.nil? && !users.empty?
      end
    end

  end

  def test_30_user_get
    return unless admin_test_possible?

    auth_admin

    assert_nothing_raised ActiveResource::ResourceNotFound, "Cannot retrieve user" do
      user = OpenStack::Keystone::Admin::User.find_by_name USER_NAME
      assert_not_nil user, "Cannot retrieve user by name"

      user = OpenStack::Keystone::Admin::User.find user.id
      assert_not_nil user, "Cannot retrieve user by id"

    end

    assert_raises ActiveResource::ResourceNotFound, "User retrieval broken!" do
      OpenStack::Keystone::Admin::User.find 1
    end

  end

  def test_40_user_update
    return unless admin_test_possible?

    auth_admin

    user = OpenStack::Keystone::Admin::User.find_by_name USER_NAME
    assert_not_nil user, "Cannot retrieve user by name"

    assert_nothing_raised ActiveResource::ResourceNotFound, "Cannot update user" do
      user.update_attributes :email => "fake2@pretend.test"
      assert_true user.save, "Failed to update server '#{user.id}': #{active_resource_errors_to_s(user)}"
    end

  end

  def test_50_role_list
    return unless admin_test_possible?

    auth_admin

    assert_nothing_raised ActiveResource::ClientError, "Cannot list roles" do
      roles = OpenStack::Keystone::Admin::Role.all

      assert_block("No roles?") do
        !roles.nil? && !roles.empty?
      end
    end

  end

  def test_60_role_get
    return unless admin_test_possible?

    auth_admin

    role = OpenStack::Keystone::Admin::Role.find_by_name TEST_CONFIG[:default_role_name]
    assert_not_nil role, "Cannot retrieve role by name"

    assert_nothing_raised ActiveResource::ResourceNotFound, "Cannot retrieve role" do
      role = OpenStack::Keystone::Admin::Role.find role.id
      assert_not_nil role, "Cannot retrieve role by id"

    end

    assert_raises ActiveResource::ResourceNotFound, "Role retrieval broken!" do
      OpenStack::Keystone::Admin::Role.find 1
    end

  end

  def test_70_user_role_add
    return unless admin_test_possible?

    auth_admin

    user = OpenStack::Keystone::Admin::User.find_by_name USER_NAME
    assert_not_nil user, "Cannot retrieve user by name"

    role = OpenStack::Keystone::Admin::Role.find_by_name TEST_CONFIG[:default_role_name]
    assert_not_nil role, "Cannot retrieve role by name"

    tenant = OpenStack::Keystone::Admin::Tenant.find(TEST_CONFIG[:user_tenant_id])
    assert_not_nil tenant, "Cannot retrieve tenant"

    assert_nothing_raised ActiveResource::ClientError, "Cannot list user roles" do
      tenant.add_role_to_user role, user
    end
  end

  def test_80_user_role_list
    return unless admin_test_possible?

    auth_admin

    user = OpenStack::Keystone::Admin::User.find_by_name USER_NAME
    assert_not_nil user, "Cannot retrieve user by name"

    assert_nothing_raised ActiveResource::ClientError, "Cannot list user roles" do
      roles = user.roles

      assert_not_nil roles
      assert_block("No user roles?") do
        !roles.empty?
      end
    end

  end

  def test_90_user_destroy
    return unless admin_test_possible?

    auth_admin

    user = OpenStack::Keystone::Admin::User.find_by_name USER_NAME
    assert_not_nil user, "Cannot retrieve user by name"

    assert_nothing_raised ActiveResource::ClientError, "Cannot destroy user" do
      user.destroy
    end

  end

end
