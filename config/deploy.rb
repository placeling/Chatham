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
    desc "Custom Thin deployment: stop"
    task :stop, :roles => :app do
        find_and_execute_task("thin:stop")
    end

    desc "Custom Thin deployment: start"
    task :start, :roles => :app do
        find_and_execute_task("thin:start")
    end

    desc "Custom Thin deployment: restart"
    task :restart, :roles => :app do
        find_and_execute_task("thin:restart")
    end
end

namespace :thin do
  %w(start stop restart).each do |action|
  desc "#{action} the app's Thin Cluster"
    task action.to_sym, :roles => :app do
      run "thin #{action} -c #{deploy_to}/current -C /etc/thin/chatham.yml -R #{deploy_to}/current/config.ru"
    end
  end
end
