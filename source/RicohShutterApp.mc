using Toybox.Application as App;

class RicohShutterApp extends App.AppBase {
	hidden var view;

    function initialize() {
        AppBase.initialize();
    }

    // onStart() is called on application start up
    function onStart(state) {
    }

    // onStop() is called when your application is exiting
    function onStop(state) {
    }

    // Return the initial view of your application here
    function getInitialView() {
    	view = new RicohShutterView();
        return [ view, new RicohShutterInputDelegate(view.method(:onError)) ];
    }

}