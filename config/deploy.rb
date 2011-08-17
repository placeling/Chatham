require 'bundler/capistrano'

set :application, "chatham"
set :repository,  "set your repository location here"

task :production do
  raise "MOFO YOU HAVENT SET UP PRODUCTION YET"
end

task :staging do
  server '204.232.211.183', :app, :web, :db, :primary => true
  set :user, 'imack'
  set :port, '11235'
  set :use_sudo, false
  set :rails_env, "staging"
end

default_run_options[:pty] = true  # Must be set for the password prompt from git to work
set :repository, "git@github.com:imackinn/Chatham.git"  # Your clone URL
set :scm, "git"

set :deploy_to, "/var/www/apps/#{application}"
set :shared_directory, "#{deploy_to}/shared"

namespace :deploy do
  task :start, :roles => :app do
    run "touch #{current_release}/tmp/restart.txt"
  end

  task :stop, :roles => :app do
    # Do nothing.
  end

  desc "Restart Application"
  task :restart, :roles => :app do
    run "touch #{current_release}/tmp/restart.txt"
  end
end

require 'config/boot'
require 'hoptoad_notifier/capistrano'
