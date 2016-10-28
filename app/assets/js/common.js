"use strict";

function parseSigs(sigs) {
  var email=document.getElement('.email');
  var sigsEl=email.getElement('table.headers tr.sig td');
  sigsEl.empty();
  if(!sigs || sigs.length == 0) {
    sigsEl.set('text', "No DKIM signatures present. This email cannot be authenticated.");
  }
  else {
    sigs.each(function(sigdata) {
      new Signature(sigdata, email);
    }); 
  }
}

function niceDate() {
  var dateEl = document.getElement(".email tr.date td");
  if(dateEl.get('text').length > 0) {
    var date = new Date(dateEl.get('text'));
    dateEl.set('text', date.toLocaleString());
  }
}

function waitForEmail(id) {
  var sub = new NchanSubscriber("/sub/podesta/"+id);
  window.subscriber = sub;
  sub.on('message', function(msg) {
    var json=JSON.decode(msg);
    var type=json[0];
    var data=json[1];
    var emailEl = document.getElement('.email');
    switch(type) {
      case "loading":
        //do nothing
        emailEl.addClass('email-loading').removeClass('hidden');
        emailEl.getElement('.headers .sig').addClass('sig-validating');
        emailEl.getElement('.headers .sig td').empty();
        break;
      case "email":
        new Email(data, emailEl);
        niceDate();
        emailEl.removeClass('email-loading');
        break;
      
      case "sigs":
        emailEl.removeClass('sig-validating');
        parseSigs(data);
        break;
        
      case "fin":
        sub.stop();
    }
    
  });
  sub.start();
  
  
}

window.Email = new Class({
  initialize: function(data, email) {
    this.data = data;
    
    (["subject", "date", "from", "to", "cc"]).each(function(hdr) {
      email.getElement("tr."+hdr+" td").set("text", data[hdr]);
    });
    
    if(email.getElement("tr.cc td").get('text')=="") {
      email.getElement("tr.cc").addClass('hidden');
    }
    
    email.getElement('.body').set('text', data.body);
  }
});

window.Signature = new Class({
  initialize: function(data, email) {
    this.data = data;
    
    var container = email.getElement("table.headers tr.sig td");
    
    var el = container.getElement(".signature[data-id=" + data.id + "]");
    
    if(el) {
      console.log(el, "already exists")
    }
    
    el=new Element("div", {'class':'signature'});
    var domain = data.domain;
    
    if(domain == "1e100.net") {
      domain = "Google";
    }
    
    var msg;
    var elClass;
    if(data.status=="pass") {
      el.addClass("valid");
      msg="Valid DKIM signature from " + domain + ". This email is definitely unaltered and authentic.";
      elClass="authentic";
    }
    else {
      elClass="inauthentic";
      if(data.status=="fail_body") {
        el.addClass("invalid-body");
        msg="Invalid DKIM signature from " + domain + ". Either the email body or the signature have been altered.";
      }
      else if(data.status=="fail_message") {
        el.addClass("invalid-message");
        msg="Invalid DKIM signature from " + domain + " -- although the email body looks unaltered, either the signature or at least one of the following appears to be altered: " + data.headernames + ". This email is not provably authentic.";
      }
      else {
        el.addClass("invalid");
        msg="Couldn't check DKIM signature from " + domain + ". This email could have been altered.";
      }
    }
    
    data.headernames.split(", ").each(function(hdr) {
      var header=email.getElement("tr."+hdr.toLowerCase());
      if(header) {
        header.addClass(elClass);
      }
    });
    email.getElement(".headers tr.sig").addClass(elClass);
    email.getElement(".body").addClass(elClass);
    
    el.adopt(new Element("p", {text: msg}));
    
    container.adopt(el);
  }
});

addEvent('domready', function() {
  //hello
});
