#!/usr/bin/ruby
source 'https://rubygems.org'
gem 'json'
gem 'cuba'
gem 'roda'
gem 'syro'
gem 'unicorn'

gem 'scrypt'

gem 'git'

gem 'mail'
gem 'rubydkim', github: 'slact/rubydkim'
gem 'sidekiq'
gem 'typhoeus'
gem 'html_to_plain_text'

#rack stuff
gem 'warden'
gem 'rack-contrib'
gem 'rack-abstract-format'
gem 'rack-respond_to'
gem 'rack-referrals'
gem 'rack-attack'
gem 'chrome_logger'
gem 'rack-detect-tor'
gem 'haml'
gem 'racksh'
gem 'redis-rack'

#rack reloader
gem "mr-sparkle"

gem "redd"

gem 'hiredis'
gem 'redis', :require => ["redis/connection/hiredis", "redis"]

#gem 'queris', git: "https://github.com/slact/queris.git"
if File.directory?(queris_path= File.expand_path("../queris"))
  gem 'queris', :path => queris_path
else
  gem 'queris', github: 'slact/queris'
end


gem 'hobbit', git: 'https://github.com/slact/hobbit.git'
gem 'hobbit-contrib', git: 'https://github.com/slact/hobbit-contrib.git', require: 'hobbit/contrib'
gem 'i18n'
gem 'rack-protection'
# Uncomment this if you want to use Sass
#gem 'sass'
gem 'sprockets'
gem 'tilt'
gem 'thin'
gem 'pandoc-ruby'

group :development do
  gem "pry"
  gem "pry-coolline"
  gem "pry-doc"
  gem "pry-remote"
  gem "pry-rescue"
  gem "pry-git"
  gem "pry-theme"
  gem 'pry-debundle'
  gem "pry-byebug", "~> 1.3.3"
  
  #gem 'awesome_print'
  gem 'better_errors'
  gem 'binding_of_caller'
  gem 'rake'
end

group :test do
  gem 'minitest', require: 'minitest/autorun'
  gem 'minitest-reporters'
  gem 'rack-test', require: 'rack/test'
end
