"use strict";

window.Signature = new Class({
  initialize: function(data, container) {
    this.data = data;
    
    var el =container.getElement(".signature[data-id=" + data.id + "]");
    
    if(el) {
      console.log(el, "already exists")
    }
    
    el=new Element("div", {'class':'signature'});
    var domain = data.domain;
    
    if(domain == "1e100.net") {
      domain = "Google";
    }
    
    var msg;
    if(data.status=="pass") {
      el.addClass("valid");
      msg="Valid DKIM signature from " + domain + ". This email is definitely unaltered and authentic.";
    }
    else if(data.status=="fail_body") {
      el.addClass("invalid-body");
      msg="Invalid DKIM signature from " + domain + ". This email could have been altered.";
    }
    else if(data.status=="fail_message") {
      el.addClass("invalid-message");
      msg="Invalid DKIM signature from " + domain + " -- although the email body is authentic, at least one of the following appears to be altered: " + data.headernames;
    }
    else {
      el.addClass("invalid");
      msg="Couldn't check DKIM signature from " + domain + ". This email could have been altered.";
    }
    
    el.adopt(new Element("p", {text: msg}));
    el.set('signature', this);
    
    container.adopt(el);
  }
});

addEvent('domready', function() {
  //hello
});
