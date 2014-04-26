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
  gem.name = "ragios-client"
  gem.homepage = "http://github.com/obi-a/ragios-client"
  gem.license = "MIT"
  gem.summary = %Q{Ruby client for ragios}
  gem.description = %Q{ruby client for ragios}
  gem.email = "obioraakubue@yahoo.com"
  gem.authors = ["obi-a"]
  # dependencies defined in Gemfile
end
Jeweler::RubygemsDotOrgTasks.new

task :repl do
  ragios_client_file = File.expand_path(File.join(File.dirname(__FILE__), '..', 'ragios-client/lib/ragios-client'))
  irb = "bundle exec pry -r #{ragios_client_file}"
  sh irb
end

task :r => :repl

task :default => :test

require 'rdoc/task'
Rake::RDocTask.new do |rdoc|
  version = File.exist?('VERSION') ? File.read('VERSION') : ""

  rdoc.rdoc_dir = 'rdoc'
  rdoc.title = "ragios-client #{version}"
  rdoc.rdoc_files.include('README*')
  rdoc.rdoc_files.include('lib/**/*.rb')
end
