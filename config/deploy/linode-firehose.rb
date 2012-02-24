set :application, "firehose"
set :repository,  "git@jaguar:firehose.git"
set :domain, "linode"
set :branch, "master"
set :user, "#{ `whoami`.chomp }"

# If you aren't deploying to /u/apps/#{application} on the target
# servers (which is the default), you can specify the actual location
# via the :deploy_to variable:
# set :deploy_to, "/var/www/#{application}"

set :scm, :git
set :deploy_via, :remote_cache
#ssh_options[:paranoid] = false
default_run_options[:pty] = true
# The above command allows for interactive commands like entering ssh passwords, but
# the problem is that "umask = 002" is getting ignored, since .profile isn't being sourced.
# :pty => true enables for a given command if we set the above to false eventually
# ssh_options[:port] = 5151   # Re-enable if we are deploying remotely again
set :use_sudo, false
# There is also this method, might be better in some cases:
# { Capistrano::CLI.ui.ask("User name: ") }

role :app, domain
role :web, domain
role :db,  domain, :primary => true

############################################################
#	Passenger
#############################################################
load 'deploy/assets'
load 'config/deploy/recipes'

before 'deploy:update', :set_umask
before "deploy:assets:precompile", :serversetup
after 'deploy:update_code', :db_migrate
after "deploy:symlink", :restartmemcached
after :restartmemcached, :redopermissions