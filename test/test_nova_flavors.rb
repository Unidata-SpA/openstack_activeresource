test_path = File.expand_path('..', __FILE__)
$:.unshift(test_path)

require 'helper'

class TestOpenStackActiveResource < Test::Unit::TestCase
  include OpenstackTestUtils

  FLAVOR_NAME="__test__flavor__"


  def test_10_flavor_create
    return unless admin_test_possible?

    auth_admin

    assert_nothing_raised ActiveResource::ClientError, "Cannot create flavors" do
      new_flavor = OpenStack::Nova::Compute::Flavor.create :name => FLAVOR_NAME,
                                                           :ram => 1,
                                                           :disk => 10,
                                                           :swap => 1,
                                                           :vcpus => 1,
                                                           :ephemeral_disk => 1,
                                                           :rxtx_factor => 1,
                                                           :is_public => false

      assert_not_nil new_flavor.id, "Cannot create flavor: #{active_resource_errors_to_s(new_flavor)}"
    end

  end

  def test_20_flavor_list
    auth_user

    assert_nothing_raised ActiveResource::ClientError, "Cannot list flavors" do
      flavors = OpenStack::Nova::Compute::Flavor.all

      assert_block("No flavors?") do
        !flavors.empty?
      end
    end
  end

  def test_20_flavor_get
    auth_user

    assert_nothing_raised ActiveResource::ResourceNotFound, "Cannot get flavors" do
      flavor = OpenStack::Nova::Compute::Flavor.first
      assert_not_nil flavor, "Cannot retrieve flavor"
    end

    return unless admin_test_possible?

    auth_admin

    flavor = OpenStack::Nova::Compute::Flavor.find_by_name FLAVOR_NAME
    assert_not_nil flavor, "Cannot retrieve flavor by name"

    assert_nothing_raised ActiveResource::ResourceNotFound, "Cannot get flavor '#{flavor.id}'" do
      flavor = OpenStack::Nova::Compute::Flavor.find flavor.id
      assert_not_nil flavor, "Cannot retrieve flavor"
    end

  end

  def test_30_flavor_update
    # Flavor cannot be updated!
  end

  def test_40_flavor_destroy
    return unless admin_test_possible?

    auth_admin

    flavor = OpenStack::Nova::Compute::Flavor.find_by_name FLAVOR_NAME
    assert_not_nil flavor, "Cannot retrieve flavor by name"

    assert_nothing_raised ActiveResource::ClientError, "Cannot destroy flavor '#{flavor.id}'" do
      flavor.destroy
    end

  end

end
