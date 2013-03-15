test_path = File.expand_path('..', __FILE__)
$:.unshift(test_path)

require 'helper'

class TestOpenStackActiveResource < Test::Unit::TestCase
  include OpenstackTestUtils

  TENANT_NAME = "__test__tenant__"

  def test_10_tenant_create
    return unless admin_test_possible?

    auth_admin

    assert_nothing_raised ActiveResource::ClientError, "Cannot create tenant" do
      new_tenant = OpenStack::Keystone::Admin::Tenant.create :name => TENANT_NAME, :enabled => true, :description => "Test tenant"

      assert_not_nil new_tenant.id, "Cannot create tenant: #{active_resource_errors_to_s(new_tenant)}"
    end
  end

  def test_20_tenant_list
    return unless admin_test_possible?

    auth_admin

    assert_nothing_raised ActiveResource::ClientError, "Cannot list tenants" do
      tenants = OpenStack::Keystone::Admin::Tenant.all

      assert_block("No tenants?") do
        !tenants.empty?
      end
    end

  end

  def test_30_tenant_get
    return unless admin_test_possible?

    auth_admin

    assert_nothing_raised ActiveResource::ResourceNotFound, "Cannot retrieve tenant '#{TEST_CONFIG[:user_tenant_id]}'" do
      tenant = OpenStack::Keystone::Admin::Tenant.find TEST_CONFIG[:user_tenant_id]
      assert_not_nil tenant, "Cannot retrieve tenant '#{TEST_CONFIG[:user_tenant_id]}'"
    end

    assert_raises ActiveResource::ResourceNotFound, "Tenant retrieval broken!" do
      OpenStack::Keystone::Admin::Tenant.find 1
    end

  end

  def test_40_tenant_update
    return unless admin_test_possible?

    auth_admin

    tenant = OpenStack::Keystone::Admin::Tenant.find_by_name TENANT_NAME

    assert_nothing_raised ActiveResource::ClientError, "Cannot update tenant '#{tenant.id}'" do
      tenant.update_attributes :enabled => false
      tenant.save
      assert_true tenant.save, "Failed to update server '#{tenant.id}': #{active_resource_errors_to_s(tenant)}"
    end
  end

  def test_50_tenant_destroy
    return unless admin_test_possible?

    auth_admin

    tenant = OpenStack::Keystone::Admin::Tenant.find_by_name TENANT_NAME

    assert_nothing_raised ActiveResource::ClientError, "Cannot destroy tenant '#{tenant.id}'" do
      tenant.destroy
    end
  end

end
