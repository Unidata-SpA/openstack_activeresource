lib_path = File.expand_path('../../lib', __FILE__)
$:.unshift(lib_path)

test_path = File.expand_path('..', __FILE__)
$:.unshift(test_path)

require 'helper'
require 'openstack_activeresource'
require 'utils'

class TestOpenStackActiveResource < Test::Unit::TestCase
  include OpenstackTestUtils

  def test_list_flavor
    auth_user

    assert_nothing_raised ActiveResource::ClientError, "Cannot list flavors" do
      flavors = OpenStack::Nova::Compute::Flavor.all

      assert_block("No flavors?") do
        !flavors.empty?
      end
    end
  end

end
