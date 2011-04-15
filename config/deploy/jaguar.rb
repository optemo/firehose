set :application, "firehose"
set :repository,  "git@jaguar:firehose.git"
set :domain, "jaguar"
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

namespace :deploy do
desc "Sync the public/assets directory."
  task :assets do
    system "rsync -vr --exclude='.DS_Store' public/system #{user}@#{domain}:#{shared_path}"
  end
  desc "Restart Application"
  task :restart do
    run "touch #{current_path}/tmp/restart.txt"
  end
end

desc "Create asset packages for production" 
task :build_assets, :roles => [:web] do
  run <<-EOF
    cd #{release_path} && rake asset:packager:build_all
  EOF
end

desc "Reindex search index"
task :reindex do
  run "rake -f #{current_path}/Rakefile ts:conf RAILS_ENV=production"
  sudo "rake -f #{current_path}/Rakefile ts:rebuild RAILS_ENV=production"
end


desc "Compile C-Code"
task :compilec do
  sudo "cmake #{current_path}/lib/c_code/clusteringCodes/"
  sudo "make hCluster"
  sudo "cp codes/hCluster #{current_path}/lib/c_code/clusteringCodes/codes/hCluster"
end

desc "Configure the server files"
task :serversetup do
  # Instantiate the database.yml file
  run "cd #{current_path}/config              && cp -f database.yml.deploy database.yml"
  #run "cd #{current_path}/config/ultrasphinx   && cp -f development.conf.deploy development.conf && cp -f production.conf.deploy production.conf"
end

task :restartmemcached do
  run "ps ax | awk '/memcached/ && !/awk/ {print $1}' > tempfile"
  sudo "xargs kill < tempfile"
  run "rm tempfile"
  run "memcached -d"
end

task :fetchAutocomplete do
  run "RAILS_ENV=production rake -f #{current_path}/Rakefile autocomplete:fetch"
end

task :redopermissions do
  run "find #{current_path} #{current_path}/../../shared -user `whoami` ! -perm /g+w -execdir chmod g+w {} +"
end

task :warmupserver do
  run "curl -A 'Java' localhost > /dev/null"
end

# redopermissions is last, so that if it fails due to the searchd pid, no other tasks get blocked
after "deploy:symlink", "build_assets"
after :build_assets, "serversetup"
after :serversetup, "redopermissions"
