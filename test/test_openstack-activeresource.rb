lib_path = File.expand_path('../../lib', __FILE__)
$:.unshift(lib_path)

test_path = File.expand_path('..', __FILE__)
$:.unshift(test_path)

require 'helper'
require 'openstack_activeresource'

class TestOpenStackActiveResource < Test::Unit::TestCase

  def auth
    OpenStack::Keystone::Public::Base.site = TEST_CONFIG[:public_base_site]

    auth = OpenStack::Keystone::Public::Auth.create :username => TEST_CONFIG[:username],
                                                    :password => TEST_CONFIG[:password],
                                                    :tenant_id => TEST_CONFIG[:tenant_id]

    OpenStack::Base.token = auth.token
    OpenStack::Nova::Compute::Base.site = auth.endpoint_for('compute').publicURL
    OpenStack::Nova::Volume::Base.site = auth.endpoint_for('volume').publicURL

  end

  def test_authentication
    OpenStack::Keystone::Public::Base.site = TEST_CONFIG[:public_base_site]

    auth = OpenStack::Keystone::Public::Auth.create :username => TEST_CONFIG[:username],
                                                    :password => TEST_CONFIG[:password],
                                                    :tenant_id => TEST_CONFIG[:tenant_id]

    assert_not_nil auth.token

    auth = OpenStack::Keystone::Public::Auth.create :username => "baduser",
                                                    :password => "badpassword",
                                                    :tenant_id => TEST_CONFIG[:tenant_id]

    assert_nil auth.token

  end

  def test_list_server
    auth

    assert_nothing_raised do
      OpenStack::Nova::Compute::Server.all
    end
  end

  def test_list_flavor
    auth

    assert_nothing_raised do
      flavors = OpenStack::Nova::Compute::Flavor.all

      assert_block("No flavors?") do
        !flavors.empty?
      end
    end
  end

  def test_list_images
    auth

    assert_nothing_raised do
      images = OpenStack::Nova::Compute::Image.all

      assert_block("No images?") do
        !images.empty?
      end
    end
  end

  def test_list_security_groups
    auth

    assert_nothing_raised do
      security_groups = OpenStack::Nova::Compute::SecurityGroup.all

      assert_block("No security_groups?") do
        !security_groups.empty?
      end
    end
  end

  def test_create_destroy_server
    auth

    flavor = OpenStack::Nova::Compute::Flavor.first
    image = OpenStack::Nova::Compute::Image.last
    security_groups = OpenStack::Nova::Compute::SecurityGroup.first

    assert_nothing_raised do
      new_server = OpenStack::Nova::Compute::Server.create :name => 'test_server',
                                                           :flavor => flavor,
                                                           :image => image,
                                                           :security_groups => [ security_groups ]
      assert_not_nil new_server

      new_server.destroy
    end



  end


end
