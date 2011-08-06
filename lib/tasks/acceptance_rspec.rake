require 'rspec/core/rake_task'
require 'ci/reporter/rake/rspec'

RSpec::Core::RakeTask.new(:acceptance_rspec => ["ci:setup:rspec"]) do |t|
  t.pattern = 'acceptance_specs/**/*_spec.rb'
end