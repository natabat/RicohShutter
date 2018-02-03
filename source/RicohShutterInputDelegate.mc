using Toybox.Application as App;
using Toybox.System;
using Toybox.WatchUi as Ui;
using Toybox.Communications;
using Toybox.Position as Pos;

class RicohShutterInputDelegate extends Ui.InputDelegate {
	static var ip_address = "http://192.168.1.1:80";
	static var execute_path = "osc/commands/execute";
	static var status_path = "osc/commands/status";
	static var state_path = "osc/state";
	
	var progressBar;
	var notifyError;

	function initialize(handler) {
		InputDelegate.initialize();
		notifyError = handler;
		inProgress("Connecting...");
		executeCommand("camera.startSession", {}, method(:startSessionCallback));
	}
	
	
	function startSessionCallback(responseCode, data) {
		debug("startSession", responseCode, data);
		if (responseCode == 200) {
			if (data["state"] != null && data["state"].equals("done")) {
				var gpsInfo = Pos.getInfo();
				var lat = 65535;
				var lng = 65535;
				if (gpsInfo != null) {
					var location = gpsInfo.position.toDegrees();
					lat = location[0];
					if (lat > 90 || lat < 90) {
						lat = 0.0;
					}
					lng = location[1];
				}
				executeCommand("camera.setOptions", 
				{
					"sessionId" => data["results"]["sessionId"],
					"options" => {
						"clientVersion" => 2
					}
				},
				method(:setInitialOptionsCallback));
			}
			else {
				progressDone();
			}
		}
		else {
			progressDone();
			notifyError.invoke();
		}
	}
	
	function setInitialOptionsCallback(responseCode, data) {
		debug("setInitialOptions", responseCode, data);
		if (responseCode == 200) {
			if (data["state"] != null && !data["state"].equals("done")) {
				getState(method(:getStateCallback));
			}
			else {
				progressDone();
			}
		}
		else {
			notifyError.invoke();
			progressDone();
		}
		
	}
	
	function getStateCallback(responseCode, data) {
		debug(getStateCallback(responseCode, data));
		if (responseCode != 200) {
			notifyError.invoke();
		}
		progressDone();
	}
	
	function onTap(clickEvent) {
		executeCommand("camera.takePicture", {}, method(:takePictureCallback));
		
		inProgress("Capturing...");
	}
	
	function takePictureCallback(responseCode, data) {
		debug("takePicture", responseCode, data);
		if (responseCode == 200) {
			if (data["state"].equals("done")) {
				progressDone();
				
			}
			else {
				checkStatus(data["id"], method(:takePictureCallback));
			}
		}
		else {
			notifyError.invoke();
			progressDone();
		}
	}
	
	function getState(callback) {
		Communications.makeWebRequest(ip_address + "/" + state_path,
			{},
			{ :method => Communications.HTTP_REQUEST_METHOD_POST, :headers => 
					{ "Content-Type" => Communications.REQUEST_CONTENT_TYPE_JSON, "Accept" => "application/json" }
			}, callback);
	}
	
	function checkStatus(id, callback) {
		Communications.makeWebRequest(ip_address + "/" + status_path,
			{"id" => id.toString()},
			{ :method => Communications.HTTP_REQUEST_METHOD_POST, :headers => 
					{ "Content-Type" => Communications.REQUEST_CONTENT_TYPE_JSON, "Accept" => "application/json" }
			}, callback);
	}

	function executeCommand(command, parameters, callback) {
		Communications.makeWebRequest(ip_address + "/" + execute_path,
			{"name" => command, "parameters" => parameters},
			{ :method => Communications.HTTP_REQUEST_METHOD_POST, :headers => 
					{ "Content-Type" => Communications.REQUEST_CONTENT_TYPE_JSON, "Accept" => "application/json" }
			}, callback);
	}
	
	function inProgress(message) {
		progressBar = new Ui.ProgressBar(message, null);
		Ui.pushView(progressBar, new RicohShutterProgressBarDelegate(self), Ui.SLIDE_DOWN);
	}
	
	function progressDone() {
		if (progressBar != null) {
			progressBar = null;
			try {
				Ui.popView(Ui.SLIDE_UP);
			} catch(ex) { }
		}
		Ui.requestUpdate();
	}	
	
	function debug(methodName, responseCode, data) {
		System.println(methodName + ": " + responseCode);
		System.println(data);
	}
	
	/*
	function onTap(clickEvent) {
		System.println("takePicture");
		executeCommand("camera.takePicture", {}, method(:onTakePicture));
		
		progressBar = new Ui.ProgressBar("Triggering", null);
		Ui.pushView(progressBar, new RicohShutterProgressBarDelegate(self), Ui.SLIDE_DOWN);
	}
	
	function initSession() {
		progressBar = new Ui.ProgressBar("Connecting", null);
		Ui.pushView(progressBar, new RicohShutterProgressBarDelegate(self), Ui.SLIDE_DOWN);
		System.println("initSession");
		executeCommand("camera.startSession", 
			{}, 
			method(:onSessionStart));		
	}
	
	function setApi(sessionId) {
		System.println("setApi");
		executeCommand("camera.setOptions", 
			{"sessionId" => sessionId, "options" => { "clientVersion" => 2}}, 
			method(:debugReturn));
	}
	
	function setGps() {
		System.println("setGps");
		var gpsInfo = Pos.getInfo();
		if (gpsInfo != null) {
			var location = gpsInfo.position.toDegrees();
			executeCommand("camera.setOptions",
				{ "gpsInfo" => 
					{
						"lat" => location[0],
						"lon" => location[1],
						"_altitude" => gpsInfo.altitude
					}
				},
				method(:debugReturn));
		}
	}
	
	
	function checkStatusCallback(responseCode, data) {
		if (responseCode == 200) {
			var state = data["state"];
			System.println("Status: " + state);
			var completion = 100;
			if (state == "inProgress" && progressBar != null) {
				completion = data["progress"]["completion"] * 100;
				progressBar.setProgress(completion);
				Ui.requestUpdate();
				checkStatus(id);
			}
			if (state == "done") {
				clearProgressBar();
			}
		}
		else {
			debugReturn(responseCode, data);
		}
	}
	
	function checkStatus(id) {
		System.println("checkStatus");
		Communications.makeWebRequest(ip_address + "/" + status_path,
			{"id" => id},
			{ :method => Communications.HTTP_REQUEST_METHOD_POST, :headers => 
					{ "Content-Type" => Communications.REQUEST_CONTENT_TYPE_JSON, "Accept" => "application/json" }
			}, method(:checkStatusCallback));
	}

	function executeCommand(command, parameters, callback) {
		Communications.makeWebRequest(ip_address + "/" + execute_path,
			{"name" => command, "parameters" => parameters},
			{ :method => Communications.HTTP_REQUEST_METHOD_POST, :headers => 
					{ "Content-Type" => Communications.REQUEST_CONTENT_TYPE_JSON, "Accept" => "application/json" }
			}, callback);
	}
	
	function onSessionStart(responseCode, data) {
		clearProgressBar();
		if (responseCode == 200) {
			var sessionId = data["results"]["sessionId"];
			setApi(sessionId);
			setGps();
		} else {
			System.println("Error: " + responseCode.toString());
			System.println("Received data: " + data);
		}
	}
	
	function onTakePicture(responseCode, data) {
		if (responseCode == 200) {
			System.println("Received data: " + data);
			var id = data["id"];
			var state = data["state"];
			if (state == "done") {
				clearProgressBar();
			}
			else {
				checkStatus(id);
			}
				
		} else {
			clearProgressBar();
			System.println("Error: " + responseCode.toString());
			System.println("Received data: " + data);
		}
		
	}
	
	function debugReturn(responseCode, data) {
		clearProgressBar();
		if (responseCode == 200) {
			System.println("Received data: " + data);
		}
		else {
			System.println("Error: " + responseCode.toString());
			System.println("Received data: " + data);
		}
	}
	
	function clearProgressBar() {
		if (progressBar != null) {
			progressBar = null;
			try {
				Ui.popView(Ui.SLIDE_UP);
			} catch(ex) { }
		}
		Ui.requestUpdate();
	}
	*/
}

class RicohShutterProgressBarDelegate extends Ui.BehaviorDelegate {
	var parent;

	function initialize(parent) {
		self.parent = parent;
		Ui.BehaviorDelegate.initialize();
	}

	function onBack() {
		parent.progressBar = null;
		Ui.requestUpdate();
	}
}