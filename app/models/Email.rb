class Email < Queris::Model
  attrs :from, :subject, :to, :date, :all_headers, :body, :authentic;
  
  before_save do |v| #validation
    throw "invalid id" if v.id.nil?
  end
end
