lib_path = File.expand_path('../../lib', __FILE__)
$:.unshift(lib_path)

test_path = File.expand_path('..', __FILE__)
$:.unshift(test_path)

require 'helper'
require 'openstack_activeresource'
require 'utils'

class TestOpenStackActiveResource < Test::Unit::TestCase
  include OpenstackTestUtils

  def test_get_quota_set
    auth_user

    assert_nothing_raised ActiveResource::ClientError, "Cannot get quota-set as user" do
      quota_set = OpenStack::Nova::Compute::QuotaSet.find TEST_CONFIG[:user_tenant_id]

      assert_not_nil quota_set, "Cannot retrieve quota-set as user"
    end

    return unless admin_test_possible?

    auth_admin

    assert_nothing_raised ActiveResource::ClientError, "Cannot get quota-set as admin" do
      quota_set = OpenStack::Nova::Compute::QuotaSet.find TEST_CONFIG[:user_tenant_id]

      assert_not_nil quota_set, "Cannot retrieve quota-set as admin"
    end
  end

  def test_update_quota_set
    auth_user

    quota_set = OpenStack::Nova::Compute::QuotaSet.find TEST_CONFIG[:user_tenant_id]
    old_instances = quota_set.instances

    assert_raises ActiveResource::ForbiddenAccess, "It shouldn't be possible for a generic user to update its quotas!" do
      quota_set.instances = old_instances + 1
      quota_set.save
    end

    return unless admin_test_possible?

    auth_admin

    quota_set = OpenStack::Nova::Compute::QuotaSet.find TEST_CONFIG[:user_tenant_id]
    old_instances = quota_set.instances

    assert_nothing_raised ActiveResource::ClientError, "Cannot update quota-set" do
      quota_set.instances = old_instances + 1
      assert quota_set.save, "Cannot update quota-set"
    end

    quota_set = OpenStack::Nova::Compute::QuotaSet.find TEST_CONFIG[:user_tenant_id]
    assert quota_set.instances == old_instances + 1, "Quota-set verification failed: not updated"

    assert_nothing_raised ActiveResource::ClientError, "Cannot get quota-set" do
      quota_set.instances = old_instances
      assert quota_set.save, "Cannot update quota-set to its original value"
    end

    quota_set = OpenStack::Nova::Compute::QuotaSet.find TEST_CONFIG[:user_tenant_id]
    assert quota_set.instances == old_instances, "Quota-set verification failed: not updated"

  end

end
