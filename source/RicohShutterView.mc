using Toybox.WatchUi as Ui;
using Toybox.Graphics as Gfx;

class RicohShutterView extends Ui.View {

	var shutter;
	var error;
	
	var inError = false;

    function initialize() {
        View.initialize();
        error = new Rez.Drawables.ErrorSign();
        shutter = new Ui.Bitmap({:rezId=>Rez.Drawables.Shutter,:locX=>20,:locY=>20});
    }

    // Load your resources here
    function onLayout(dc) {
        setLayout(Rez.Layouts.MainLayout(dc));
    }

    // Called when this View is brought to the foreground. Restore
    // the state of this View and prepare it to be shown. This includes
    // loading resources into memory.
    function onShow() {
    }

    // Update the view
    function onUpdate(dc) {
        // Call the parent onUpdate function to redraw the layout
        View.onUpdate(dc);
        dc.setColor(Gfx.COLOR_BLACK, Gfx.COLOR_BLACK);
        dc.fillRectangle(0, 0, dc.getWidth(), dc.getHeight());
        
        if (!inError) {
        	shutter.draw(dc);
        }
        else {
        	error.draw(dc);
        }
    }
    
    function onError() {
    	inError = true;
    	Ui.requestUpdate();
    }
    
    

    // Called when this View is removed from the screen. Save the
    // state of this View here. This includes freeing resources from
    // memory.
    function onHide() {
    }

}
