lib_path = File.expand_path('../../lib', __FILE__)
$:.unshift(lib_path)

test_path = File.expand_path('..', __FILE__)
$:.unshift(test_path)

require 'helper'
require 'openstack_activeresource'
require 'utils'

class TestOpenStackActiveResource < Test::Unit::TestCase
  include OpenstackTestUtils

  def test_list_security_groups
    auth_user

    assert_nothing_raised ActiveResource::ClientError, "Cannot list security group" do
      security_groups = OpenStack::Nova::Compute::SecurityGroup.all

      assert_block("No security_groups?") do
        !security_groups.empty?
      end
    end
  end

end
