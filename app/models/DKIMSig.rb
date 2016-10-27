class DKIMSig < Queris::Model
  
  attrs :email_id, type: Fixnum
  attrs :status, :domain, :algorithm, :headernames, :selector, :version;
  attrs :canon_body, :canon_headers, type: Fixnum
  
  index_attribute :email_id
  index_attribute :status
  
  def parse(sig)
    self.status= sig.status
    self.domain= sig.domain
    self.algorithm= sig.algo == 0 ? "rsa-sha256" : "rsa-sha1"
    self.headernames= sig.headernames.gsub(":", ", ")
    self.selector= sig.selector
    self.canon_body= sig.canon_body
    self.canon_headers= sig.canon_headers
  end
  
  def email
    Email.find(email_id)
  end
end
