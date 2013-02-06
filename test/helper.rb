require 'rubygems'
require 'bundler'
begin
  Bundler.setup(:default, :development)
rescue Bundler::BundlerError => e
  $stderr.puts e.message
  $stderr.puts "Run `bundle install` to install missing gems"
  exit e.status_code
end
require 'test/unit'
require 'shoulda'

$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
$LOAD_PATH.unshift(File.dirname(__FILE__))
require 'openstack_activeresource'

class Test::Unit::TestCase
end

# Load test configuration for OpenStack API
test_path = File.expand_path('..', __FILE__)
$:.unshift(test_path)

unless  File.exist? "#{test_path}/test_configuration.ymla"
  raise "\n****" +
            "\n**** Please add a valid 'test_configuration.yml' file in '#{test_path}'." +
            "\n**** See #{test_path}/test_configuration-sample.yml for an example" +
            "\n****"
end

TEST_CONFIG = (YAML.load_file("#{test_path}/test_configuration.yml")['test_configuration']).with_indifferent_access

