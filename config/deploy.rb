set :stages, %w(jaguar linode slicehost uniserve-firehose)
require 'capistrano/ext/multistage'
require 'bundler/capistrano'
# The next two lines are needed for integration with Ruby Version Manager:
set :rvm_ruby_string, '1.9.3'