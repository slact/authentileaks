require "pry" 
module Authentileaks
  class Application < Hobbit::Base
    use Rack::MethodOverride
    
    #autoload controllers, mapping them to basic routes by name
    descendants.each do |ctrl|
      match = ctrl.name.match(".*?::(.*)Controller")
      if match
        name = match[1].downcase!
        if name == "root"
          url="/"
        else
          url="/#{name}"
        end
        
        #puts "map #{url} to #{ctrl.name}"
        map(url) do
          run ctrl.new
        end
      end      
    end
  end
end
