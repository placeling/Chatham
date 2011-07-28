require 'rspec/core/rake_task'
require 'ci/reporter/rake/rspec'
require "bundler/rake"


RSpec::Core::RakeTask.new(:ci_rspec => ["bundle:install", "ci:setup:rspec"]) do |t|
  t.pattern = '**/*_spec.rb'
end