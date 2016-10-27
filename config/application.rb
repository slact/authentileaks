require 'bundler'
require 'securerandom'
require "yaml"
require "queris"

Bundler.require :default, ENV['RACK_ENV'].to_sym

module Authentileaks
  class Application < Hobbit::Base
    def self.descendants
      ObjectSpace.each_object(Class).select { |klass| klass < self }
    end
    
    
    include Hobbit::Render
    #include Hobbit::Session
    #include Hobbit::Filter
    include Hobbit::Environment
    
    #load config
    all_conf=YAML.load_file 'config/env.yml'
    conf=all_conf[ENV['RACK_ENV']]
    @@config=conf
    def config
      @@config
    end
    
    Queris.add_redis Redis.new(url: conf["redis_url"])
    
    use Rack::Config do |env|
      all_conf[ENV['RACK_ENV'].to_s].each do |cf, val|
        env[cf.to_sym]=val
      end
    end
    
    (Dir['config/initializers/**/*.rb'] + 
     Dir['app/models/**/*.rb'] +
     Dir['app/controllers/**/*.rb']).each do |file| 
      require File.expand_path(file)
    end

    if development?
      #use PryRescue::Rack
      use BetterErrors::Middleware
    end
    #use Rack::Session::Redis
    # must be used after Rack::Session::Cookie
    #use Rack::Protection, except: :http_origin
    
    #static resources
    use Rack::Static, root: 'app/assets/', urls: ['/js', '/css', '/img', '/icons', '/documents']
    use Rack::Static, root: 'app/assets/', urls: ['/packages']
    
    def find_template(template)
      tmpl_path=@@templates[template.to_sym]
      raise "template #{template} not found" unless tmpl_path
      tmpl_path
    end
    def default_layout
      find_template :"layouts/application"
    end
    def template_engine
      raise "template_engine shouldn't be called"
    end
      
    #convenience methods
    def user
      env['warden'].user
    end
    

    def set_content_type (val)
      response.headers["Content-Type"]=val
    end
    def json_response!
      set_content_type "application/json"
    end
    def js_response!
      set_content_type "application/javascript"
    end
    
    def params
      request.params
    end
    def param(name)
      params[name]
    end
    
  end
end

require File.expand_path('config/routes.rb')
