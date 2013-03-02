test_path = File.expand_path('..', __FILE__)
$:.unshift(test_path)

require 'helper'

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

  def test_list_security_group_rules
    auth_user

    security_group = OpenStack::Nova::Compute::SecurityGroup.first

    assert_nothing_raised ActiveResource::ClientError, "Cannot list security group rules" do

      security_group_rules = security_group.rules
      assert_not_nil security_group_rules

      assert_block("No rules?") do
        !security_group_rules.empty?
      end
    end
  end

end
