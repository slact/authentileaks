require "sidekiq"
require 'sidekiq/testing/inline'
require "typhoeus"
require "mail"
require 'dkim'

class EmailWorker
  include Sidekiq::Worker

  class RawishEmail
    def initialize(raw)
      @raw=raw
      @headers, @body = @raw.split("\r\n\r\n", 2)
    end
    
    def header_exists(name)
      @headers.match(/^#{name}/i)
    end
    
    def rename_header(name, newname)
      @headers.gsub!(/^#{name}/i, newname)
    end
    
    def to_s
      "#{@headers}\r\n\r\n#{@body}"
    end
  end
  
  
  def perform(wikileaks_id)
    resp = Typhoeus.get("https://www.wikileaks.org/podesta-emails/get/#{wikileaks_id}", followlocation: true)
    
    if resp.code != 200
      #error!
    end
    
    
    email = Email.new(wikileaks_id)
    email.parse(resp.body)
    email.leakname="podesta"
    email.save
    
    #display email
    
    rawmail = RawishEmail.new resp.body
    rawmail.rename_header("X-Google-DKIM-Signature", "DKIM-Signature")
    
    ver = DKIM::Verifier.new
    
    ver.feed rawmail.to_s
    
    sigs = ver.finish
    
    sigs.each do |sig|
      dkim_sig = DKIMSig.new
      dkim_sig.email_id = email.id
      dkim_sig.parse(sig)
      dkim_sig.save
    end
    
    email.sigs
  end
end
