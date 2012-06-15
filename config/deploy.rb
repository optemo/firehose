set :stages, %w(jaguar linode slicehost uniserve-firehose)
require 'capistrano/ext/multistage'
require 'bundler/capistrano'
# The next two lines are needed for integration with Ruby Version Manager:
$:.unshift(File.expand_path('./lib', ENV['rvm_path'])) # Add RVM's lib directory to the load path.
require "rvm/capistrano"                  # Load RVM's capistrano plugin.
set :rvm_ruby_string, '1.9.3'