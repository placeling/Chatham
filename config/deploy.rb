require 'bundler/capistrano'

set :application, "chatham"

set :rvm_ruby_string, "ruby-1.9.3-p125"
require "rvm/capistrano"                               # Load RVM's capistrano plugin.

before 'deploy:setup', 'rvm:install_rvm'
before 'deploy:setup', 'rvm:install_ruby'


task :production do
  set :gateway, 'beagle.placeling.com:11235'
  server '10.196.210.55', :app, :web, :db, :primary => true
  ssh_options[:forward_agent] = true #forwards local-localhost keys through gateway
  set :user, 'ubuntu'
  set :use_sudo, false
  set :rails_env, "production"
end

task :staging do
  server 'staging.placeling.com', :app, :web, :db, :primary => true
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

  desc "Hot-reload God configuration for the Resque worker"
  task :reload_god_config do
    sudo "god stop resque"
    sudo "god load #{File.join(deploy_to, 'current', 'config', 'resque-' + rails_env + '.god')}"
    sudo "god start resque"
  end


end

namespace :db do
  task :reload, :roles => :app do
    run("cd #{deploy_to}/current && bundle exec rake RAILS_ENV=#{rails_env} db:reload")
  end
end

require 'config/boot'
require 'hoptoad_notifier/capistrano'

#after :deploy, "deploy:reload_god_config"