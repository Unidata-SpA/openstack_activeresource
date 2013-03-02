test_path = File.expand_path('..', __FILE__)
$:.unshift(test_path)

require 'helper'

class TestOpenStackActiveResource < Test::Unit::TestCase
  include OpenstackTestUtils

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

end
