require "sidekiq"
require "typhoeus"
require "mail"
require 'dkim'

Sidekiq.configure_server do |config|
  config.redis = { url: Authentileaks::Application.conf["redis_url"] }
end

module Authentileaks
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
    
    def conf
      Authentileaks::Application.conf
    end
    
    def pub(id, data_type, data="")
      pub_url="http://#{conf["nchan_pub_host"]}/pub/podesta/#{id}"
      
      post_data = [data_type, data]
      
      Typhoeus.post(pub_url, headers: {'Content-Type' => 'text/json'}, body: post_data.to_json)
    end
    
    def parse(id, email, email_body)
      email.parse(email_body)

      
      email.save
      pub id, "email", email
      
      #display email
      
      rawmail = RawishEmail.new email_body
      rawmail.rename_header("X-Google-DKIM-Signature", "DKIM-Signature")
      
      ver = DKIM::Verifier.new
      
      ver.feed rawmail.to_s
      
      raw_sigs = ver.finish
      
      sigs = []
      
      raw_sigs.each do |sig|
        dkim_sig = DKIMSig.new
        dkim_sig.email_id = email.id
        dkim_sig.parse(sig)
        dkim_sig.save
        
        sigs << dkim_sig
      end
      sleep 10
      pub id, "sigs", sigs
      
      email.signed= !sigs.empty?
      email.job_running= false
      email.save
      
      pub id, "fin"
    end
    
    def perform(id)
      email = Email.find(id)
      return if email && email.job_running

      pub id, "loading"
      
      email = Email.new(id)
      email.leakname="podesta"
      email.job_running=true
      email.save
      
      resp = Typhoeus.get("https://www.wikileaks.org/podesta-emails/get/#{id}", followlocation: true, timeout: 5)
      if resp.code != 200
        pub id, "error", "got response code #{resp.code}"
        email.delete
        return 
      end
      
      parse id, email, resp.body
    end
  end
end
