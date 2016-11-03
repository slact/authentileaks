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
    
    LAST_LEAK_KEY="Authentileaks:last_leak_id"
    
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
      
      def each_chunk
        max = 64000
        yield @headers
        yield "\r\n\r\n"
        if @body.length > max 
          n=0
          while n * max < @body.length
            yield @body[n * max, max]
            n+=1
          end
        else
          yield @body
        end
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
    
    
    def parse_sigs(email, email_body)
      rawmail = RawishEmail.new email_body
      rawmail.rename_header("X-Google-DKIM-Signature", "DKIM-Signature")
      
      ver = DKIM::Verifier.new
      
      rawmail.each_chunk do |chunk|
        ver.feed chunk
      end
      
      raw_sigs = ver.finish
      sigs = []
      
      raw_sigs.each do |sig|
        dkim_sig = DKIMSig.new
        dkim_sig.email_id = email.id
        dkim_sig.parse(sig)
        sigs << dkim_sig
      end
      
      sigs
    end
    
    def save_sigs(sigs)
      sigs.each do |sig|
        sig.save
      end
    end
    
    def parse(id, email, email_body, nopub=false)
      email.parse(email_body)
      
      email.save
      pub id, "email", email unless nopub
      
      #display email
      
      sigs = parse_sigs(email, email_body)
      save_sigs(sigs)
      
      pub id, "sigs", sigs unless nopub
      
      email.signed= !sigs.empty?
      email.job_running= false
      email.save
      
      pub id, "fin" unless nopub
      true
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
        return false
      end
      
      return parse id, email, resp.body
    end
  end
end
