require 'bundler/capistrano'

set :application, "chatham"

set :rvm_ruby_string, "ruby-1.9.3-p125"
require "rvm/capistrano"                               # Load RVM's capistrano plugin.

before 'deploy:setup', 'ubuntu:required_packages'
before 'deploy:setup', 'rvm:install_rvm'
before 'deploy:setup', 'rvm:install_ruby'

after "deploy:create_symlink", "deploy:restart_workers"
after "deploy:create_symlink", "deploy:restart_scheduler"

SitemapGenerator::Sitemap.sitemaps_path = 'shared/'

task :production do
  set :gateway, 'beagle.placeling.com:11235'
  server '10.112.241.90', :app, :web, :db, :scheduler, :primary => true
  ssh_options[:forward_agent] = true #forwards local-localhost keys through gateway
  set :user, 'ubuntu'
  set :use_sudo, false
  set :rails_env, "production"
end

task :staging do
  server 'staging.placeling.com', :app, :web, :db, :scheduler, :primary => true
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


def run_remote_rake(rake_cmd)
  rake_args = ENV['RAKE_ARGS'].to_s.split(',')
  cmd = "cd #{fetch(:latest_release)} && #{fetch(:rake, "rake")} RAILS_ENV=#{fetch(:rails_env, "production")} #{rake_cmd}"
  cmd += "['#{rake_args.join("','")}']" unless rake_args.empty?
  run cmd
  set :rakefile, nil if exists?(:rakefile)
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

  desc "Restart Resque Workers"
  task :restart_workers, :roles => :app do
    run_remote_rake "resque:restart_workers"
  end

  desc "Restart Resque scheduler"
  task :restart_scheduler,:roles => :scheduler do
    run_remote_rake "resque:restart_scheduler"
  end

end

namespace :ubuntu do
  task :required_packages, :roles => :app do
    run 'sudo apt-get update'
    run 'sudo apt-get install git-core ruby  ruby-dev rubygems libxslt-dev libxml2-dev libcurl4-openssl-dev imagemagick'
    run 'sudo apt-get install zlib1g-dev libssl-dev libyaml-dev libsqlite3-0  libsqlite3-dev sqlite3 libxml2-dev libxslt-dev  autoconf libc6-dev ncurses-dev'
    run 'sudo apt-get install build-essential bison openssl libreadline6 libreadline6-dev curl libtool libpcre3 libpcre3-dev'
  end

  task :service_gems, :roles => :app do
    run 'gem install bundler passenger scout request-log-analyzer'
  end

end


namespace :db do
  task :reload, :roles => :app do
    run("cd #{deploy_to}/current && bundle exec rake RAILS_ENV=#{rails_env} db:reload")
  end
end

desc "Compile asets"
task :assets do
  run "cd #{release_path}; RAILS_ENV=#{rails_env} bundle exec rake assets:precompile"
end

require 'airbrake/capistrano'

#after :deploy, "deploy:reload_god_config"
        require './config/boot'
        require 'airbrake/capistrano'
