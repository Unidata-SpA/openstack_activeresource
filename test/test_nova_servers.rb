lib_path = File.expand_path('../../lib', __FILE__)
$:.unshift(lib_path)

test_path = File.expand_path('..', __FILE__)
$:.unshift(test_path)

require 'helper'
require 'openstack_activeresource'
require 'utils'

class TestOpenStackActiveResource < Test::Unit::TestCase
  include OpenstackTestUtils

  # Servers

  def test_list_server
    auth_user

    assert_nothing_raised ActiveResource::ClientError, "Cannot list server" do
      OpenStack::Nova::Compute::Server.all
    end
  end

  def test_server_create_destroy
    auth_user

    flavor = OpenStack::Nova::Compute::Flavor.find_by_name TEST_CONFIG[:flavor_name]
    assert_not_nil flavor

    image = OpenStack::Nova::Compute::Image.find TEST_CONFIG[:image_id]
    assert_not_nil image

    new_server_id = nil
    assert_nothing_raised ActiveResource::ClientError, "Failed to create a new server" do
      new_server = OpenStack::Nova::Compute::Server.create :name => 'test_server',
                                                           :flavor => flavor,
                                                           :image => image
      assert_not_nil new_server
      new_server_id = new_server.id
    end

    # Verify server
    my_server = loop_block(5) do
      begin
        OpenStack::Nova::Compute::Server.find new_server_id
      rescue ActiveResource::ResourceNotFound

        nil
      end
    end
    assert_not_nil my_server, "Server not spawned after 5 seconds!?!"

    # Wait for a network address
    my_address = loop_block(60) do
      my_server = OpenStack::Nova::Compute::Server.find new_server_id
      my_server.addresses.keys.count > 0 ? my_server.addresses : nil
    end
    assert_not_nil my_address, "No address after a minute!"

    assert_nothing_raised ActiveResource::ClientError, "Problem retrieving the server '#{new_server_id}'" do
      my_server = OpenStack::Nova::Compute::Server.find new_server_id
      my_server.destroy
    end

  end


end
