test_path = File.expand_path('..', __FILE__)
$:.unshift(test_path)

require 'helper'

class TestOpenStackActiveResource < Test::Unit::TestCase
  include OpenstackTestUtils

  def test_floating_ip_list
    auth_user

    assert_nothing_raised ActiveResource::ClientError, "Cannot list floating IP" do
      floating_ips = OpenStack::Nova::Compute::FloatingIp.all

      assert_not_nil floating_ips, "Cannot retrieve floating IP list"
    end
  end

  def test_floating_ip_allocation
    auth_user

    assert_nothing_raised ActiveResource::ClientError, "Cannot list floating IP" do
      floating_ip = nil
      OpenStack::Nova::Compute::FloatingIpPool.all.each do |ip_pool|
        begin
          floating_ip = OpenStack::Nova::Compute::FloatingIp.create(:pool => ip_pool.name)
          break
        rescue ActiveResource::ClientError => e
          next # Retry with the next pool
        end
      end

      assert_not_nil floating_ip, "Failed to allocate a floating IP"

      floating_ip.destroy
    end
  end

end
