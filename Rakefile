# encoding: utf-8

require 'rubygems'
require 'bundler'
begin
  Bundler.setup(:default, :development)
rescue Bundler::BundlerError => e
  $stderr.puts e.message
  $stderr.puts "Run `bundle install` to install missing gems"
  exit e.status_code
end
require 'rake'

require 'jeweler'
Jeweler::Tasks.new do |gem|
  # gem is a Gem::Specification... see http://docs.rubygems.org/read/chapter/20 for more options
  gem.name = "openstack_activeresource"
  gem.homepage = "https://github.com/Unidata-SpA/openstack_activeresource"
  gem.license = "GPLv3"
  gem.summary = %Q{OpenStack Ruby and RoR bindings implemented with ActiveResource}
  gem.description = %Q{OpenStack Ruby and RoR bindings implemented with ActiveResource - See also http://www.unicloud.it}
  gem.email = "d.guerri@unidata.it"
  gem.authors = ["Davide Guerri"]
  # dependencies defined in Gemfile
end
Jeweler::RubygemsDotOrgTasks.new

desc "Code coverage detail"
task :simplecov do
  ENV['COVERAGE'] = "true"
  Rake::Task['<%= test_task %>'].execute
end

task :default => :test

require 'rdoc/task'
Rake::RDocTask.new do |rdoc|
  version = File.exist?('VERSION') ? File.read('VERSION') : ""

  rdoc.rdoc_dir = 'rdoc'
  rdoc.title = "OpenStack-ActiveResource #{version}"
  rdoc.rdoc_files.include('README*')
  rdoc.rdoc_files.include('lib/**/*.rb')
end
