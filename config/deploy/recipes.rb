############################################################
#	Passenger
#############################################################

namespace :deploy do
  desc "Restart Application"
  task :restart do
    run "touch #{current_path}/tmp/restart.txt"
  end
end

desc "Reindex search index"
task :reindex do
  run "rake -f #{current_path}/Rakefile ts:conf RAILS_ENV=production"
  sudo "rake -f #{current_path}/Rakefile ts:rebuild RAILS_ENV=production"
end

desc "Configure the server files"
task :serversetup do
  # Instantiate the database.yml file
  run "cd #{latest_release}/config              && cp -f database.yml.deploy database.yml"
  #run "cd #{current_path}/config/ultrasphinx   && cp -f development.conf.deploy development.conf && cp -f production.conf.deploy production.conf"
end

task :restartmemcached do
  run "cd #{current_path} && bundle exec rake -f #{current_path}/Rakefile cache:clear RAILS_ENV=production"
end

task :redopermissions do
  run "find #{current_path} #{current_path}/../../shared -user `whoami` ! -perm /g+w -execdir chmod g+w {} +"
end

task :warmupserver do
  run "curl -A 'Java' localhost > /dev/null"
end

task :set_umask do
  run "umask 0002"
end