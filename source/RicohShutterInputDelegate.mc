using Toybox.Application as App;
using Toybox.System;
using Toybox.WatchUi as Ui;
using Toybox.Communications;
using Toybox.Position as Pos;

class RicohShutterInputDelegate extends Ui.InputDelegate {
	static var ip_address = "http://192.168.1.1:80";
	static var execute_path = "osc/commands/execute";
	static var status_path = "/osc/commands/status";
	
	var progressBar;

	function initialize() {
		InputDelegate.initialize();
		initSession();
	}
	
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
		Communications.makeJsonRequest(ip_address + "/" + status_path,
			{"id" => id},
			{ :method => Communications.HTTP_REQUEST_METHOD_POST, :headers => 
					{ "Content-Type" => Communications.REQUEST_CONTENT_TYPE_JSON, "Accept" => "application/json" }
			}, method(:checkStatusCallback));
	}

	function executeCommand(command, parameters, callback) {
		Communications.makeJsonRequest(ip_address + "/" + execute_path,
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