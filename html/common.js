var baseServURI;

// this file copied from https://github.com/drogatkin/Webbee/blob/master/src/js/common.js
// JavaScript tool and utilities
// Copyright (c) 2025 Dmitriy Rogatkin
// All rights reserved.


function submitFormOnEnter (field, evt) {
   var keyCode = evt.which ? evt.which : evt.keyCode;
   if (keyCode == 13) {
      field.form.submit();
      return false;
   } else 
      return true;
}

function getOffsetLeft (el) {
  var ol = el.offsetLeft;
  while ((el = el.offsetParent) != null)
    ol += el.offsetLeft;
  return ol;
}

function getOffsetTop (el) {
  var ot = el.offsetTop;
  while((el = el.offsetParent) != null)
   ot += el.offsetTop;
  return ot;
}

function centerElement(el)  {
	  var left=0, top=0;
	  if( self.pageYOffset ) {
	    left = self.pageXOffset;
	     top = self.pageYOffset;
	  } else if( document.documentElement && document.documentElement.scrollTop ) {
	    left = document.documentElement.scrollLeft;
	    top = document.documentElement.scrollTop;
	  } else if( document.body ) {
	     left = document.body.scrollLeft;
	     top = document.body.scrollTop;
	  } 
	  
	  el.style.left = Math.max((left + (getWindowWidth() - el.offsetWidth) / 2), 0) + 'px';
	  el.style.top = Math.max((top + (getWindowHeight() - el.offsetHeight) / 2), 0) + 'px';
	  //el.style.position='fixed';
 }

function getWindowWidth() {
	var width =
		document.documentElement && document.documentElement.clientWidth ||
		document.body && document.body.clientWidth ||
		document.body && document.body.parentNode && document.body.parentNode.clientWidth ||
		0;

	return width;
}
 
function getWindowHeight() {
    var height =
		document.documentElement && document.documentElement.clientHeight ||
		document.body && document.body.clientHeight ||
  		document.body && document.body.parentNode && document.body.parentNode.clientHeight ||
  		0;
  		
  	return height;
}

function htmlEncode(s) {
    return String(s).replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;').replace(/"/g, '&quot;')
}

function htmlAttrEncode(s) {
    return String(s).replace(/"/g, '&quot;')
}

function decodeHtmlEntity(text) {
    var entities = [
        ['amp', '&'],
        ['apos', '\''],
        ['#x27', '\''],
        ['#x2F', '/'],
        ['#39', '\''],
        ['#47', '/'],
        ['lt', '<'],
        ['gt', '>'],
        ['nbsp', ' '],
        ['quot', '"']
    ];

    for (var i = 0, max = entities.length; i < max; ++i)
        text = text.replace(new RegExp('&' + entities[i][0] + ';', 'g'), entities[i][1]);

    return text  
}

function message(key) {
	// TODO use key in lookup localized message association
	if (localized_messages) {
		var mess = localized_messages[key];
		if (mess) {
			getElement('status').innerHTML = mess;
			return;
		}			
	}
	getElement('status').innerHTML = key;
}

function submitPage(base, anchor, res, massageData) {
	const url = base+anchor.substring(1)
	const frm = document.querySelector(res) || document.querySelector('form')
	const xhr = new XMLHttpRequest()
	
	if(massageData && typeof massageData === 'function')
       massageData()
	
	const fd = new FormData( frm )

    // Define what happens on successful data submission
    xhr.addEventListener( "load", function(event) {
     // alert( event.target.responseText )
      location.hash = '#'+ event.target.responseText
    } )

    // Define what happens in case of error
    xhr.addEventListener( "error", function( event ) {
      if (defaultErrorHandlers && defaultErrorHandlers.submitError && typeof defaultErrorHandlers.submitError === "function")
          defaultErrorHandlers.submitError(event) // instanceof Function
    } )

    // Set up our request
    xhr.open( "POST", url );

    // The data sent is what the user provided in the form
    xhr.send( fd );
}

function convertEpochToSpecificTimezone(timeEpoch, offset){
    var d = new Date(timeEpoch);
    var utc = d.getTime() + (d.getTimezoneOffset() * 60000);  //This converts to UTC 00:00
    var nd = new Date(utc + (3600000*offset));
    return nd.toLocaleString();
}

function normalizePath(path,separator,root) {
    separator = separator || '/'
    root = root || ''
  // Remove multiple slashes
  if (separator ==  '/') {
    path = path.replace(/\/\/+/g, separator);
  } else {
    path = path.replace(/\\\\+/g, separator);
  }
  let segments = path.split(separator);
  let normalizedSegments = [];

  for (let segment of segments) {
    if (segment === '..') {
      normalizedSegments.pop(); // Go up one directory
    } else if (segment !== '.' && segment !== '') {
      normalizedSegments.push(segment); // Push valid directory names
    }
  }

  return (separator == '/'?'/':'') + normalizedSegments.join(separator); // Reconstruct the path
}

// use the method for normalized paths
function getLastPathComponent(path) {
     path = path.replace(/\/\/+/g, '/');
     path = path.replaceAll('\\', '/');
    let segments = path.split('/');
    if (segments.length === 0) {
        return ''
    }
    return segments.pop();
}

function makeid(length) {
    let result = '';
    const characters = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';
    const charactersLength = characters.length;
    let counter = 0;
    while (counter < length) {
      result += characters.charAt(Math.floor(Math.random() * charactersLength));
      counter += 1;
    }
    return result;
}

var audioCtx
function beep() {
    if (!audioCtx)
       audioCtx = new(window.AudioContext || window.webkitAudioContext)();
  var oscillator = audioCtx.createOscillator();
  var gainNode = audioCtx.createGain();

  oscillator.connect(gainNode);
  gainNode.connect(audioCtx.destination);

  gainNode.gain.value = 0.3;
  oscillator.frequency.value = 1200;
  oscillator.type = 'sine';
  duration = 155 // ms
  oscillator.start();

  setTimeout(
    function() {
      oscillator.stop();
    },
    duration
  );
}

const trimString = (str, maxLength) => {
  if (str.length <= maxLength) {
    return str;
  }
  
  return str.slice(0, maxLength) + '...';
};

var ajax = {
   noaccesscode:403,

   noaccessredirect:'/',

   put: function(req) {
	   var self = this
      var xhr = new XMLHttpRequest();
      xhr.open('PUT', req.url);
      xhr.setRequestHeader('Content-Type', 'application/json');
      xhr.onload = function () {
    	  self.processResponse(xhr,req) 
      }
      xhr.send(JSON.stringify(req.payload));
   },

   get: function(req) {
	   var self = this
	   var xhr = new XMLHttpRequest();
	      xhr.open('GET', req.url);
	      xhr.onload = function () {
	    	  self.processResponse(xhr,req) 
	      }
	      xhr.send();
   },
   
   post: function(req) {
	   var self = this
	   var xhr = new XMLHttpRequest();
	      xhr.open('POST', req.url, true)
          xhr.setRequestHeader("Content-Type", "application/x-www-form-urlencoded")
	      xhr.onload = function () {
	    	  self.processResponse(xhr,req) 
	      }
	      xhr.send(req.query);
   },
   
   dele: function(req) {
	   // TODO think of reusing put
	   var self = this
	      var xhr = new XMLHttpRequest();
	      xhr.open('DELETE', req.url);
	      xhr.setRequestHeader('Content-Type', 'application/json');
	      xhr.onload = function () {
	    	  self.processResponse(xhr,req) 
	      }
	      xhr.send(JSON.stringify(req.payload));
   }, 
   
   processResponse: function (xhr,req) {
       if (xhr.status === 200) {
    	   if (req.respType && req.respType === 'html')
    		   req.success(xhr.responseText)
    	   else	
           try {
        	   req.success(JSON.parse(xhr.responseText));
           } catch(e) {
              if (typeof req.fail === 'function')
                  req.fail( xhr.status, e )
           }
        } else if (this.noaccesscode === xhr.status &&  this.noaccessredirect) {
           window.location = this.noaccessredirect
        } else if (typeof req.fail === 'function')
           req.fail( xhr.status, xhr.responseText )
   }
}