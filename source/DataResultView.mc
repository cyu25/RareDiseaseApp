
import Toybox.Graphics;
import Toybox.WatchUi;
import Toybox.Lang;

class DateResultView extends WatchUi.View {

    var dateString as String;
    var hasData as Boolean;

    function initialize(date as String, dataExists as Boolean) {
        View.initialize();
        dateString = date;
        hasData = dataExists;
    }

    function onLayout(dc as Dc) as Void {
    }

    function onShow() as Void {
    }

    function onUpdate(dc as Dc) as Void {
        var width = dc.getWidth();
        var height = dc.getHeight();
        var centerX = width / 2;
        var centerY = height / 2;
        
        // White background
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_WHITE);
        dc.clear();
        
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_TRANSPARENT);
        
        dc.drawText(centerX, centerY - 20, Graphics.FONT_SMALL, "No data reported", 
                    Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        dc.drawText(centerX, centerY + 20, Graphics.FONT_TINY, "on " + dateString, 
                    Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
    }

    function onHide() as Void {
    }
}


class DateResultDelegate extends WatchUi.BehaviorDelegate {

    function initialize() {
        BehaviorDelegate.initialize();
    }

    // BACK button - go back to calendar
    function onBack() as Boolean {
        WatchUi.popView(WatchUi.SLIDE_RIGHT);
        return true;
    }
    
    function onSelect() as Boolean {
        // Go back to calendar
        WatchUi.popView(WatchUi.SLIDE_RIGHT);
        return true;
    }
}
