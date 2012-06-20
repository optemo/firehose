set :stages, %w(jaguar linode slicehost uniserve-firehose)
# The next two lines are needed for integration with Ruby Version Manager:
set :rvm_type, :system
set :rvm_ruby_string, '1.9.3'
require 'capistrano/ext/multistage'
require 'bundler/capistrano'
require "rvm/capistrano"                  # Load RVM's capistrano plugin.
