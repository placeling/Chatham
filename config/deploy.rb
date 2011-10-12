require 'bundler/capistrano'

set :application, "chatham"
set :repository,  "set your repository location here"

task :production do
  set :gateway, 'ubuntu@ec2-174-129-147-96.compute-1.amazonaws.com:11235'
  server '10.209.115.58', :app, :web, :db, :primary => true
  ssh_options[:forward_agent] = true #forwards local-localhost keys through gateway
  set :user, 'ubuntu'
  set :use_sudo, false
  set :rails_env, "production"
end

task :staging do
  server 'ec2-50-18-132-90.us-west-1.compute.amazonaws.com', :app, :web, :db, :primary => true
  ssh_options[:forward_agent] = true
  set :user, 'ubuntu'
  set :port, '11235'
  set :use_sudo, false
  set :rails_env, "staging"
end

default_run_options[:pty] = true  # Must be set for the password prompt from git to work
set :repository, "git@github.com:imackinn/Chatham.git"  # Your clone URL
set :scm, "git"

set :deploy_to, "/var/www/apps/#{application}"
set :shared_directory, "#{deploy_to}/shared"
set :deploy_via, :remote_cache

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
