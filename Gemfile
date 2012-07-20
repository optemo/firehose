source 'http://rubygems.org'

gem 'rails', '3.2.2'

# Bundle edge Rails instead:
# gem 'rails', :git => 'git://github.com/rails/rails.git'

gem 'mysql2', '> 0.3'

# Use unicorn as the web server
# gem 'unicorn'

# Deploy with Capistrano
gem 'capistrano'
gem 'capistrano-ext'
gem 'rvm-capistrano'

# Bundle the extra gems:
# gem 'bj'
# gem 'nokogiri'
# gem 'sqlite3-ruby', :require => 'sqlite3'
# gem 'aws-s3', :require => 'aws/s3'

group :development do
   gem 'sunspot_solr', :git=> "git://github.com/wildoats/sunspot.git", :branch=>"optemo" # optional pre-packaged Solr distribution for use in development
   #gem 'sunspot_solr', :git=> "git://github.com/sunspot/sunspot.git" # optional pre-packaged Solr distribution for use in development
end

# Bundle gems for the local environment. Make sure to
# put test-only gems in this group so their generators
# and rake tasks are available in development mode:
group :development, :test do
  gem 'debugger'
end

gem 'i18n-active_record',
    #:git => 'git://github.com/svenfuchs/i18n-active_record.git',
    #Set_table_name is deprecated, so we'll use this patched version
    :git => 'git://github.com/Studentify/i18n-active_record.git',
    :require => 'i18n/active_record'

# In firehose, use this in development mode too
gem "dalli", "1.0.2"
gem 'json'
gem 'activerecord-import'
gem 'capistrano'
gem 'capistrano-ext'
gem 'rubyzip'
gem 'jquery-rails'
gem 'jstree-rails', :git => 'git://github.com/tristanm/jstree-rails.git'
gem 'sunspot_rails', :git=> "git://github.com/wildoats/sunspot.git", :branch=>"optemo"
gem 'ruby_core_source'
gem 'progress_bar'
# for amazon
gem 'aws-sdk'
#gem 'ruby-aws'
gem 'ruby-aaws'
gem 'nokogiri'

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
  # gem 'growl_notify'
  gem 'factory_girl_rails'
end

group :accessories do
end

# Gems used only for assets and not required
# in production environments by default.
group :assets do
  gem 'sass-rails'
  gem 'coffee-rails'
  gem 'uglifier'
  gem 'yui-compressor'
  gem 'execjs'
  gem 'therubyracer'
end
