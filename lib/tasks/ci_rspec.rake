require 'rspec/core/rake_task'
require 'ci/reporter/rake/rspec'

RSpec::Core::RakeTask.new(:ci_rspec => ["ci:setup:rspec"]) do |t|
  t.pattern = 'spec/**/*_spec.rb'
end