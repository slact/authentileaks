require 'rake/testtask'

Rake::TestTask.new do |t|
  t.libs << 'spec'
  t.pattern = 'spec/**/*_spec.rb'
end

desc 'Start a console'
task :console do
  ENV['RACK_ENV'] ||= 'development'
  require "pry"
#  require "pry-debundle"

  require_relative 'config/application'

  ARGV.clear
  pry
end

desc 'grab leaks from files'
task :parsefiles, [:path, :first, :last]  do |t, arg|
  ENV['RACK_ENV'] ||= 'development'
  require_relative 'config/application'
  ARGV.clear

  dir, first, last = arg[:path], arg[:first].to_i, arg[:last].to_i
  worker = Authentileaks::EmailWorker.new
  for i in first..last do
    path="#{dir}/#{i}.eml"
    begin
      eml=File.read path
    rescue
      eml=nil
    end
    if eml
      email=Email.find(i)
      if email.nil?
        email=Email.new(i)
        begin
          worker.parse(i, email, eml)
          puts "parsed  email #{i}"
        rescue Exception => e
          email.sigs.each{ |sig| sig.delete }
          email.delete
          Authentileaks::EmailWorker.perform_async(i)
          puts "parsing email #{i}, got error #{e}.  sidekiqing."
        end
      else
        puts "skipped email #{i}"
      end
    else
      puts "bad file #{path}"
    end
  end
end

desc 'grab leaks from wikileaks'
task :parseleaks, [:first, :last]  do |t, arg|
  ENV['RACK_ENV'] ||= 'development'
  require_relative 'config/application'
  ARGV.clear

  first, last = arg[:first].to_i, arg[:last].to_i
  worker = Authentileaks::EmailWorker.new
  for i in first..last do
    email=Email.find(i)
    if email.nil?
      email=Email.new(i)
      ret= worker.perform(i)
      if ret
        puts "parsed  email #{i}"
      else
        puts "email #{i} not found"
      end
    else
      puts "skipped email #{i}"
    end
  end
end

desc 'grab new leaks from wikileaks'
task :newleaks  do |t, arg|
  ENV['RACK_ENV'] ||= 'development'
  require_relative 'config/application'
  ARGV.clear

  worker = Authentileaks::EmailWorker.new
  first = Queris.redis.get Authentileaks::EmailWorker::LAST_LEAK_KEY
  first ||= 1
  i= first
  n=0
  loop do
    email=Email.find(i)
    if email.nil?
      email=Email.new(i)
      ret= worker.perform(i)
      if ret
        puts "parsed  email #{i}"
        n+=1
      else
        puts "email #{i} not found"
        break
      end
    else
      puts "skipped email #{i}"
    end
    i+=1
  end
  puts "parsed #{n} emails"
end

task default: :test
