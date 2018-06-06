/*! by Tom Thorogood <me@tomthorogood.co.uk> */
/*! This work is licensed under the Creative Commons Attribution 4.0
International License. To view a copy of this license, visit
http://creativecommons.org/licenses/by/4.0/ or see LICENSE. */

// setImmediate is a 0-delay setTimeout of sorts introduced
// by MS and wrongly held back by other browsers
window.setImmediate || !function (global) {
	// Get the global prototype to attach setImmediate to
	let attachTo = Object.getPrototypeOf && Object.getPrototypeOf(global);
	
	// If we couldn't get the prototype or setTimeout wasn't attached
	// to the prototype we just attach to global
	attachTo && attachTo.setTimeout || (attachTo = global);
	
	// If the MS prefixed implementation exists, use it
	if (global.msSetImmediate) {
		return attachTo.setImmediate = global.msSetImmediate, attachTo.clearImmediate = global.msClearImmediate;
	}
	
	// https://github.com/YuzuJS/setImmediate/blob/master/setImmediate.js
	// This checks if the current environment is Node.js
	if (global.process && Object.prototype.toString(global.process) === "[object process]") {
		// If it is we might be able to use timers
		let timers = global.require("timers");
		
		// If it implements setImmediate we use it
		if (timers && timers.setImmediate) {
			return attachTo.setImmediate = timers.setImmediate, attachTo.clearImmediate = timers.clearImmediate;
		}
		
		// If it isn't we polyfill with nextTick which is
		// sufficiently similar
		if (global.process.nextTick) {
			return attachTo.setImmediate = function (func, ...params) {
				// Invoke func with the params as passed into setImmediate
				global.process.nextTick(() => func(...params));
			}, attachTo.clearImmediate = function (immediateID) {
				// There is no id or way to stop nextTick
				throw new Error("clearImmediate not implemented");
			};
		}
	}
	
	// http://dbaron.org/log/20100309-faster-timeouts
	// https://github.com/YuzuJS/setImmediate/blob/master/setImmediate.js
	// https://github.com/kriskowal/q/blob/0428c15d2ffc8e874b4be3a50e92884ef8701a6f/q.js#L125-141
	// If we have messaging channels, or we have postMessage and this
	// isn't a WebWorker, we can use messaging
	if (global.MessageChannel || global.postMessage && !global.importScripts && (function () {
		// This checks if global.postMessage is asynchronous,
		// it has been known to be buggy and synchronous in
		// some browsers
		let postMessageIsAsynchronous = true;
		let oldOnMessage = global.onmessage;
		global.onmessage = function () { postMessageIsAsynchronous = false; };
		global.postMessage("", "*");
		global.onmessage = oldOnMessage;
		return postMessageIsAsynchronous;
	})()) {
		// A unique id prefix to ensure that ONLY valid messages are accepted
		let messageName = `setImmediate-polyfill-${Math.random()}`.replace("0.", "");
		
		// The numeric identifier of the next dispatched scrypt call
		let immediateID = 1;
		
		// The timeout function and arguments, indexed by numeric identifier
		let timeouts = { };
		
		// If a MessageChannel exists we can use it to avoid sending
		// messages to the browser which could cause interoperability
		// issues
		let channel = global.MessageChannel && new global.MessageChannel();
		
		// We need to start port1 in order to receive messages sent
		// from port2
		channel && channel.port1.start();
		
		// Add a handler to the message event of either the message
		// channel, if it exists, or global if it does not
		(channel && channel.port1 || global).addEventListener("message", function (event) {
			// If event data is not a string, i.e. doesn't implement split,
			// we didn't send it
			if (!event.data || !event.data.split) {
				return;
			}
			
			// Split the identifier into the name and numeric id
			let [name, immediateID] = event.data.split("$");
			
			// If we are not using a MessageChannel check that the source
			// of the event was this window, also check the name is valid,
			// if either of these are not true, we didn't send it
			if (!channel && event.source !== global || name !== messageName) {
				return;
			}
			
			// Prevent the event from propagating further
			event.stopPropagation();
			
			// Retrieve the function and the arguments we will invoke
			// leaving func and params as null if the immediateID
			// does not exist in timeouts (because clearImmediate has
			// been called before we got here)
			let [func, params] = timeouts[immediateID] || [ ];
			
			// Invoke the func with the appropriate parameters
			func && func(...params);
			
			// Clear func and params for GC
			func = params = null;
			
			// Remove key:immediateID from timeouts to ensure it's only
			// called once and to allow for GC
			delete timeouts[immediateID];
		}, false);
		
		return attachTo.setImmediate = function (func, ...params) {
			// Store the function and it's arguments in timeouts
			timeouts[immediateID] = [func, params];
			
			// Post the message either using port2 of the MessageChannel
			// or on global if it's not available w/ the unique id
			// If the message is sent on global we dispatch it w/ a
			// targetOrigin of "*" (indicating no preference)
			(channel && channel.port2 || global).postMessage([messageName, immediateID].join("$"), ...(channel ? [ ] : ["*"]));
			
			// We return a unique numeric id to identify the call
			// to setImmediate, this allows it to be cancelled
			return immediateID++;
		}, attachTo.clearImmediate = function (immediateID) {
			// Delete the function and arguments associated
			// w/ identifier of immediateID
			delete timeouts[immediateID];
		};
	}
	
	// Set setImmediate to prefixed or non-prefixed requestAnimationFrame
	// requestAnimationFrame dispatches at a later point in the event cycle
	attachTo.setImmediate = global.requestAnimationFrame || global.mozRequestAnimationFrame || global.webkitRequestAnimationFrame || global.msRequestAnimationFrame;
	
	// If requestAnimationFrame existed we end, setting clearImmediate
	// to cancelAnimationFrame
	if (attachTo.setImmediate) {
		return attachTo.clearImmediate = global.cancelAnimationFrame || global.mozCancelAnimationFrame || global.webkitCancelAnimationFrame || global.msCancelAnimationFrame || global.webkitCancelRequestAnimationFrame;
	}
	
	// https://github.com/YuzuJS/setImmediate/blob/master/setImmediate.js
	// We can use a script tag and the readystatechange event on IE(?)
	if (global.document && "onreadystatechange" in global.document.getElementsByTagName("script")[0]) {
		// The numeric identifier of the next dispatched scrypt call
		let immediateID = 1;
		
		// A boolean value to allow clearImmediate to work,
		// indexed by numeric identifier
		let timeouts = { };
		
		return attachTo.setImmediate = function (func, ...params) {
			// Set true in timeouts for immediateID to indicate the func
			// should be invoked
			timeouts[immediateID] = true;
			
			// Create a script tag that will be added to the DOM
			let script = global.document.createElement("script");
			
			// Add a handler for onreadystatechange
			script.onreadystatechange = function () {
				// If the timeout has not been cancelled, call the func
				// w/ the arguments specified
				timeouts[immediateID] && func(...params);
				
				// Remove key:immediateID from timeouts to ensure it's only called once 
				delete timeouts[immediateID];
				
				// Remove the handler to allow GC
				script.onreadystatechange = null;
				
				// Remove the script tag from the DOM to ensure GC
				global.document.body.removeChild(script);
				
				// Nullify the script variable to allow GC
				script = null;
			};
			
			// Add the script tag to the DOM to which begins loading
			// the tag which will invoke the readystatechange event
			global.document.body.appendChild(script);
			
			// Return a unique numeric id to identify the call
			// to setImmediate, this allows it to be cancelled
			return immediateID++;
		}, attachTo.clearImmediate = function (immediateID) {
			// Remove key:immediateID from timeouts to prevent func from being called
			delete timeouts[immediateID];
		};
	}
	
	// The worst fallback is setTimeout, although the delay is set to 0,
	// in reality this should have a ~20ms delay as this is an important
	// part of the spec
	attachTo.setImmediate = (func, ...params) => global.setTimeout(func, 0, ...params);
	attachTo.clearImmediate = global.clearTimeout;
	
	// Here we check if the arguments passed to setTimeout actually will be
	// passed to the callback, on older versions of IE(?) this check will fail
	global.setTimeout(function (arg) {
		// If the test fails, we wrap func in a closure that will invoke func w/
		// the arguments
		arg || (attachTo.setImmediate = (func, ...params) => global.setTimeout(() => func(...params), 0));
	}, 0, true);
}(this || window);