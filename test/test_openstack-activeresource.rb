lib_path = File.expand_path('../../lib', __FILE__)
$:.unshift(lib_path)

test_path = File.expand_path('..', __FILE__)
$:.unshift(test_path)

require 'helper'
require 'openstack_activeresource'

class TestOpenStackActiveResource < Test::Unit::TestCase

  # Keystone

  # Authentication

  def test_authentication
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

  def test_simple_tenant_usage
    return unless admin_test_possible?

    auth_admin

    assert_nothing_raised ActiveResource::ClientError, "Cannot retrieve simple_usages" do
      simple_usages = OpenStack::Nova::Compute::SimpleTenantUsage.find_from_date(:all, 5.days.ago)

      assert_not_nil simple_usages
    end

  end

  # Nova

  ## Flavors

  def test_list_flavor
    auth_user

    assert_nothing_raised ActiveResource::ClientError, "Cannot list flavors" do
      flavors = OpenStack::Nova::Compute::Flavor.all

      assert_block("No flavors?") do
        !flavors.empty?
      end
    end
  end

  # Images

  def test_list_images
    auth_user

    assert_nothing_raised ActiveResource::ClientError, "Cannot list images" do
      images = OpenStack::Nova::Compute::Image.all

      assert_block("No images?") do
        !images.empty?
      end
    end
  end

  # Security groups

  def test_list_security_groups
    auth_user

    assert_nothing_raised ActiveResource::ClientError, "Cannot list security group" do
      security_groups = OpenStack::Nova::Compute::SecurityGroup.all

      assert_block("No security_groups?") do
        !security_groups.empty?
      end
    end
  end

  # Keypairs

  def test_keypair_list
    auth_user

    assert_nothing_raised ActiveResource::ClientError, "Cannot list keypair" do
      keys = OpenStack::Nova::Compute::KeyPair.all

      assert_not_nil keys, "Cannot retrieve key-pairs"
    end

  end

  def test_keypair_create_destroy
    auth_user

    keypair_name = '___my_new_keypair'
    key = nil
    assert_nothing_raised ActiveResource::ClientError, "Cannot create key pair" do
      key = OpenStack::Nova::Compute::KeyPair.create :name => keypair_name
    end
    assert_not_nil key, "Cannot create key pair"

    key = nil
    assert_nothing_raised ActiveResource::ClientError, "Cannot find keypair '#{keypair_name}'" do
      key = OpenStack::Nova::Compute::KeyPair.find_by_name keypair_name
    end

    assert_not_nil key, "Cannot find key pair"

    assert_nothing_raised "Cannot destroy key pair" do
      key.destroy
    end

  end

  # Floating IPs
  def test_floating_ip_list
    auth_user

    assert_nothing_raised ActiveResource::ClientError, "Cannot list floating IP" do
      floating_ips = OpenStack::Nova::Compute::FloatingIp.all

      assert_not_nil floating_ips, "Cannot retrieve key-pairs"
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

  private

  # Utilities

  def auth_admin
    OpenStack::Keystone::Public::Base.site = TEST_CONFIG[:public_base_site]
    OpenStack::Keystone::Admin::Base.site = TEST_CONFIG[:public_admin_site]

    auth = OpenStack::Keystone::Public::Auth.create :username => TEST_CONFIG[:admin_username],
                                                    :password => TEST_CONFIG[:admin_password],
                                                    :tenant_id => TEST_CONFIG[:admin_tenant_id]

    OpenStack::Base.token = auth.token
    OpenStack::Nova::Compute::Base.site = auth.endpoint_for('compute').publicURL
    OpenStack::Nova::Volume::Base.site = auth.endpoint_for('volume').publicURL

  end

  def auth_user
    OpenStack::Keystone::Public::Base.site = TEST_CONFIG[:public_base_site]

    auth = OpenStack::Keystone::Public::Auth.create :username => TEST_CONFIG[:user_username],
                                                    :password => TEST_CONFIG[:user_password],
                                                    :tenant_id => TEST_CONFIG[:user_tenant_id]

    OpenStack::Base.token = auth.token
    OpenStack::Nova::Compute::Base.site = auth.endpoint_for('compute').publicURL
    OpenStack::Nova::Volume::Base.site = auth.endpoint_for('volume').publicURL

  end

  def admin_test_possible?
    TEST_CONFIG[:admin_username] and TEST_CONFIG[:admin_password] and TEST_CONFIG[:admin_tenant_id]
  end

  def loop_block(seconds=10)
    ret = nil
    if block_given? and seconds > 0
      begin
        ret = yield
        return ret unless ret.nil?
        seconds-=1
        sleep 1
      end while seconds > 0
    end

    ret
  end

end
