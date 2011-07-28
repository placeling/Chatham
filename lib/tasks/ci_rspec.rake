require 'rspec/core/rake_task'
require 'ci/reporter/rake/rspec'


task :bundle_install do
  sh 'bundle install'
end


RSpec::Core::RakeTask.new(:ci_rspec => [:bundle_install, "ci:setup:rspec"]) do |t|
  t.pattern = 'spec/**/*_spec.rb'
end