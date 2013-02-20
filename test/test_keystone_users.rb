lib_path = File.expand_path('../../lib', __FILE__)
$:.unshift(lib_path)

test_path = File.expand_path('..', __FILE__)
$:.unshift(test_path)

require 'helper'
require 'openstack_activeresource'
require 'utils'

class TestOpenStackActiveResource < Test::Unit::TestCase
  include OpenstackTestUtils

  def test_list_users
    return unless admin_test_possible?

    auth_admin

    assert_nothing_raised ActiveResource::ClientError, "Cannot list users" do
      users = OpenStack::Keystone::Admin::User.all

      assert_block("No users?") do
        !users.nil? && !users.empty?
      end
    end

  end

  def test_list_user_roles
    return unless admin_test_possible?

    auth_admin

    user = OpenStack::Keystone::Admin::User.first

    assert_nothing_raised ActiveResource::ClientError, "Cannot list user roles" do

      roles = user.roles

      assert_not_nil roles
      assert_block("No users?") do
        !roles.empty?
      end
    end

  end

end
