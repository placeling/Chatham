require 'bundler/capistrano'

set :application, "chatham"

set :rvm_ruby_string, "ruby-1.9.3-p125"
require "rvm/capistrano" # Load RVM's capistrano plugin.

before 'deploy:setup', 'rvm:install_rvm'
before 'deploy:setup', 'rvm:install_ruby'

after "deploy:create_symlink", "make_upload_dir"

server 'beagle.placeling.com', :app, :web, :db, :scheduler, :primary => true
set :user, 'ubuntu'
set :use_sudo, false
set :rails_env, "production"
set :port, 11235

default_run_options[:pty] = true # Must be set for the password prompt from git to work
set :repository, "git@github.com:imackinn/Chatham.git" # Your clone URL
set :scm, "git"

set :deploy_to, "/var/www/apps/#{application}"
set :shared_directory, "#{deploy_to}/shared"
set :deploy_via, :remote_cache


task :make_upload_dir do
  run "ln -nfs #{shared_path}/uploads #{release_path}/public/uploads"
end

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


namespace :db do
  task :reload, :roles => :app do
    run("cd #{deploy_to}/current && bundle exec rake RAILS_ENV=#{rails_env} db:reload")
  end
end

require './config/boot'
