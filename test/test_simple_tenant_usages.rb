lib_path = File.expand_path('../../lib', __FILE__)
$:.unshift(lib_path)

test_path = File.expand_path('..', __FILE__)
$:.unshift(test_path)

require 'helper'
require 'openstack_activeresource'
require 'utils'

class TestOpenStackActiveResource < Test::Unit::TestCase
  include OpenstackTestUtils

  def test_simple_tenant_usage
    return unless admin_test_possible?

    auth_admin

    assert_nothing_raised ActiveResource::ClientError, "Cannot retrieve simple_usages" do
      simple_usages = OpenStack::Nova::Compute::SimpleTenantUsage.find_from_date(:all, 5.days.ago)

      assert_not_nil simple_usages
    end

  end

end
