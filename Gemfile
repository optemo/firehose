source 'http://rubygems.org'

gem 'rails', '3.1.1'

# Bundle edge Rails instead:
# gem 'rails', :git => 'git://github.com/rails/rails.git'

gem 'mysql2', '0.3.7'

# Use unicorn as the web server
# gem 'unicorn'

# Deploy with Capistrano
# gem 'capistrano'

# To use debugger (ruby-debug for Ruby 1.8.7+, ruby-debug19 for Ruby 1.9.2+)
# gem 'ruby-debug'
#gem 'ruby-debug19'

# Bundle the extra gems:
# gem 'bj'
# gem 'nokogiri'
# gem 'sqlite3-ruby', :require => 'sqlite3'
# gem 'aws-s3', :require => 'aws/s3'

# Bundle gems for the local environment. Make sure to
# put test-only gems in this group so their generators
# and rake tasks are available in development mode:
# group :development, :test do
#   gem 'webrat'
# end

# In firehose, use this in development mode too
gem "dalli", "1.0.2"
gem 'json'
gem 'activerecord-import'
gem 'capistrano'
gem 'capistrano-ext'
gem 'rubyzip'
gem 'jquery-rails'

group :development do
  gem 'rspec-rails'
end

group :production do
#  gem 'newrelic_rpm'
end

group :test do
  gem 'spork', '> 0.9.0.rc'
  gem 'spork-testunit'
  gem 'guard-test'
  gem 'guard-spork'
  gem 'rb-fsevent'
  gem 'ruby-prof'
  gem 'growl_notify'
  gem 'factory_girl_rails'
  #gem 'webrat', '0.7.3'
end

# Gems used only for assets and not required
# in production environments by default.
group :assets do
  gem 'sass-rails', "  ~> 3.1.0"
  gem 'coffee-rails', "~> 3.1.0"
  gem 'uglifier'
end
