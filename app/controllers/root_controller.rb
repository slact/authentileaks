class Authentileaks::RootController < Authentileaks::Application
  get '/' do
    
    arg={
      total_count: 0,
      count: Email.count,
      count_signed: Email.count_signed,
      count_authentic: Email.count_authentic,
      title: "Irrefutably authentic emails from the Podesta email leaks."
    }
    
    arg[:count_signed_pct]=arg[:count]==0 ? 0 : ((arg[:count_signed].to_f / arg[:count].to_f) * 100).round
    arg[:signed_authentic_percent]=arg[:count_signed]==0 ? 0 : ((arg[:count_authentic].to_f / arg[:count_signed].to_f) * 100).round
    arg[:unknown_or_inauthentic] = arg[:count] - arg[:count_authentic];
    render 'index', arg
  end
  
  get /(?<id>\d+)/ do

    email= Email.find(params["id"])
    
    #if email
    #  email.sigs.each do |sig|
    #    sig.delete
    #  end
    #  email.delete
    #end
    
    unless email
      EmailWorker.perform_async(params["id"])
      email=Email.new(params["id"])
    end
    
    render 'email', email: email, title: "Email ID #{params["id"]}"
  end
  
  any "/email", [:get, :post] do
    response.redirect "/#{params["emailid"]}"
  end
  
  #404
  any /.*/, [:get, :post, :put, :delete] do
    response.status = 404
    render '404', title: "Page Not Found"
  end
  
end
