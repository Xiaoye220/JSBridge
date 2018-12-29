;
(function() {
	if (window.bridge) {
		return;
	}
	window.bridge = function() {
		var handlers = {},
		    callbacks = {},
			jsCallbackId = 0;

		function postMessage(message) {
			if (window.webkit && window.webkit.messageHandlers && window.webkit.messageHandlers.bridge) {
				window.webkit.messageHandlers.bridge.postMessage(message);
			}
		}

		function responseToSwift(name, data, swiftCallbackId) {
			postMessage({
				"name": name,
				"data": data,
				"swiftCallbackId": swiftCallbackId,
			});
		}

		return {
			"register": function(name, handler) {
				handlers[name] = handler;
			},
			"call": function(name, data, callback) {
				var id = (jsCallbackId++).toString();
				callbacks[id] = callback;
				postMessage({
					"name": name,
					"data": data,
					"jsCallbackId": id,
				});
			},
			"callFromSwift": function(message) {
				var name = message.name;
				var data = message.data;
				var jsCallbackId = message.jsCallbackId;
				var swiftCallbackId = message.swiftCallbackId;

				if (jsCallbackId) {
					var jsCallback = callbacks[jsCallbackId];
					if (jsCallback) {
						jsCallback(data);
						delete callbacks[jsCallbackId];
					}
				} else {
					var swiftCallBack;
					if (swiftCallbackId) {
						swiftCallBack = function(data) {
							responseToSwift(name, data, swiftCallbackId);
						};
					}
					var handler = handlers[name];
					if (handler) {
						handler(data, swiftCallBack)
					}
				}
			}
		}
	}()



})();