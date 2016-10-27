class Authentileaks::RootController < Authentileaks::Application
  get '/' do
    render 'index'
  end
  
  get /(?<id>\d+)/ do

    email= Email.find(params["id"])
    
    if !email
      EmailWorker.perform_async(params["id"])
    end
    
    render 'email'
  end
  
  #404
  any /.*/, [:get, :post, :put, :delete] do
    response.status = 404
    render '404'
  end
  
end
