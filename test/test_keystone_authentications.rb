lib_path = File.expand_path('../../lib', __FILE__)
$:.unshift(lib_path)

test_path = File.expand_path('..', __FILE__)
$:.unshift(test_path)

require 'helper'
require 'openstack_activeresource'
require 'utils'

class TestOpenStackActiveResource < Test::Unit::TestCase
  include OpenstackTestUtils

  # Keystone

  # Authentication

  def test_authentications
    OpenStack::Keystone::Public::Base.site = TEST_CONFIG[:public_base_site]

    # User auth
    assert_nothing_raised ActiveResource::ClientError, "Cannot authenticate as user" do
      auth = OpenStack::Keystone::Public::Auth.create :username => TEST_CONFIG[:user_username],
                                                      :password => TEST_CONFIG[:user_password],
                                                      :tenant_id => TEST_CONFIG[:user_tenant_id]

      assert_not_nil auth.token, "Cannot authenticate as user"

      auth = OpenStack::Keystone::Public::Auth.create :username => "baduser",
                                                      :password => "badpassword",
                                                      :tenant_id => TEST_CONFIG[:user_tenant_id]

      assert_nil auth.token, "Authentication seems broken!"
    end

    # Admin auth
    return unless admin_test_possible?

    assert_nothing_raised ActiveResource::ClientError, "Cannot authenticate as admin" do
      auth = OpenStack::Keystone::Public::Auth.create :username => TEST_CONFIG[:admin_username],
                                                      :password => TEST_CONFIG[:admin_password],
                                                      :tenant_id => TEST_CONFIG[:admin_tenant_id]

      assert_not_nil auth.token, "Cannot authenticate as admin"
    end

  end

end
