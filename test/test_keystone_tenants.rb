lib_path = File.expand_path('../../lib', __FILE__)
$:.unshift(lib_path)

test_path = File.expand_path('..', __FILE__)
$:.unshift(test_path)

require 'helper'
require 'openstack_activeresource'
require 'utils'

class TestOpenStackActiveResource < Test::Unit::TestCase
  include OpenstackTestUtils

  def test_list_tenant
    return unless admin_test_possible?

    auth_admin

    assert_nothing_raised ActiveResource::ClientError, "Cannot list tenants" do
      tenants = OpenStack::Keystone::Public::Tenant.all

      assert_block("No tenants?") do
        !tenants.empty?
      end
    end

  end

end
