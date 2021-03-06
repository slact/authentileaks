require 'html_to_plain_text'
require "mail"

require_relative "DKIMSig"

class Email < Queris::Model
  
  attrs :from, :subject, :to, :cc, :date, :body, :leakname
  attrs :job_running, :signed, type: :bool
  attr :time, type: Float
  attr :length, type: Fixnum
  
  index_attribute :signed
  index_attribute name: :all, attribute: :id, value: proc {|v| '(...)'}
  index_attribute_from model: DKIMSig, name: :sig_status, attribute: :status, key: :email_id
  
  index_range_attribute :time
  index_range_attribute :id
  
  def stringy(val)
    if Enumerable === val
      val.join ", "
    else
      val.to_s
    end
  end
  
  def getcharset(mail)
    return mail.charset if mail.charset
    if mail.multipart?
      mail.parts.each do |part|
        charset= getcharset(part)
        return charset if charset
      end
    end
  end
  
  def getbody(mail)
    bestbody={}
    
    if mail.multipart?
      mail.parts.each do |part|
        if part.multipart?
          b, m=getbody(part)
          bestbody[m]=b
        else
          b=part.body.to_s
          b.force_encoding(part.charset) if part.charset
          bestbody[part.mime_type]=b
        end
      end
    else
      b=mail.body.to_s
      b.force_encoding(mail.charset) if mail.charset
      bestbody[mail.mime_type]=b
    end
    ["text/plain", "text/html"].each do |mime|
      return bestbody[mime], mime if bestbody[mime]
    end
    k, v = bestbody.first
    return v, k
  end
  
  def parse(message)
    mail= Mail.new(message)
    
    #charset= getcharset(mail)
    
    self.from= stringy(mail.from)
    self.subject= mail.subject
    self.subject.encode!("utf-8", :invalid => :replace, :undef => :replace) if self.subject
    self.to= stringy(mail.to)
    self.cc= stringy(mail.cc)
    self.date= mail.date
    self.body, mime = getbody(mail)
    if mime=="text/html"
      self.body= HtmlToPlainText.plain_text(self.body)
    end
    self.body.encode!("utf-8", :invalid => :replace, :undef => :replace) if self.body
    self.length = message.length
  end
  
  def sigs
    if @id
      sigs=DKIMSig.query.union(:email_id, id).results
    else
      []
    end
  end
  
  def to_json(opt={})
    opt[:invalid] = :replace;
    opt[:undef] = :replace,
    opt[:replace] = '?'
    super
  end
  
  before_save do |v| #validation
    throw "invalid id" if v.id.nil?
    v.noload do
      if v.date && v.time.nil?
        v.time= DateTime.parse(v.date.to_s).to_time.utc.to_f
      end
    end
  end
  
  def delete
    sigs.each { |sig| sig.delete } if @id
    super
  end
  
  def self.count
    self.query.union(:all).count
  end
  def self.count_authentic
    self.query.union(:sig_status, :pass).count
  end
  def self.count_signed
    self.query.union(:signed, true).count
  end
  
end
