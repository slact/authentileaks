require "mail"
class Email < Queris::Model
  
  attrs :from, :subject, :to, :cc, :date, :body, :leakname;
  
  def parse(message)
    mail= Mail.new(message)
    self.from= mail.from.join ", "
    self.subject= mail.subject
    self.to= mail.to.join ", "
    self.cc= mail.cc.join ", "
    self.date= mail.date
    if mail.multipart?
      mail.parts.each do |part|
        self.body=part.body if part.mime_type=="text/plain"
      end
    else
      self.body= mail.body
    end
    self.to= mail.to.join ", "
  end
  
  def to_json
    super(sigs: sigs)
  end
  
  def sigs
    if @id
      DKIMSig.query.union(:email_id, id).results
    else
      []
    end
  end
  
  before_save do |v| #validation
    throw "invalid id" if v.id.nil?
  end
end
