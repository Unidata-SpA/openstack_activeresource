test_path = File.expand_path('..', __FILE__)
$:.unshift(test_path)

require 'helper'

class TestOpenStackActiveResource < Test::Unit::TestCase
  include OpenstackTestUtils

  def test_list_images
    auth_user

    assert_nothing_raised ActiveResource::ClientError, "Cannot list images" do
      images = OpenStack::Nova::Compute::Image.all

      assert_block("No images?") do
        !images.empty?
      end
    end
  end

end
