require 'rake/testtask'

Rake::TestTask.new do |t|
  t.libs << 'spec'
  t.pattern = 'spec/**/*_spec.rb'
end

desc 'Start a console'
task :console do
  ENV['RACK_ENV'] ||= 'development'
  require "pry"
  require "pry-debundle"

  require_relative 'config/application'

  ARGV.clear
  pry
end

desc 'grab new leaks'
task :newleaks  do
  ENV['RACK_ENV'] ||= 'development'
  require_relative 'config/application'
  ARGV.clear

end

task default: :test
