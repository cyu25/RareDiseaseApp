
import Toybox.WatchUi;
import Toybox.Graphics;
import Toybox.Lang;

class YesPageView extends WatchUi.View {
    
    function initialize() {
        View.initialize();
    }

    function onUpdate(dc as Dc) as Void {
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.clear();
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(
            dc.getWidth() / 2,
            dc.getHeight() / 2.2,
            Graphics.FONT_SMALL,
            "Are there any" +
            "\n symptoms \nto report?",
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER
        );

        var screenWidth = dc.getWidth();
        var screenHeight = dc.getHeight();
        var buttonWidth = 100;
        var buttonHeight = 50;

        // YES button
        var yesX = (screenWidth * 28) / 100;
        var yesY = (screenHeight * 76) / 100;

        dc.setColor(Graphics.COLOR_BLUE, Graphics.COLOR_TRANSPARENT);
        dc.fillRoundedRectangle(
            yesX - buttonWidth/2,
            yesY - buttonHeight/2,
            buttonWidth,
            buttonHeight,
            8
        );

        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(
            yesX,
            yesY,
            Graphics.FONT_MEDIUM,
            "YES",
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER
        );

        // SKIP button
        var skipX = (screenWidth * 69) / 100;
        var skipY = (screenHeight * 76) / 100;

        dc.setColor(Graphics.COLOR_ORANGE, Graphics.COLOR_TRANSPARENT);
        dc.fillRoundedRectangle(
            skipX - buttonWidth/2,
            skipY - buttonHeight/2,
            buttonWidth,
            buttonHeight,
            8
        );

        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(
            skipX,
            skipY,
            Graphics.FONT_MEDIUM,
            "NO",
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER
        );
        }

    
}

class YesPageDelegate extends WatchUi.BehaviorDelegate {
    
    function initialize() {
        BehaviorDelegate.initialize();
    }

    function onBack() as Lang.Boolean {
        WatchUi.popView(WatchUi.SLIDE_DOWN);
        return true;
    }

    function onTap(clickEvent as ClickEvent) as Lang.Boolean {
        var coords = clickEvent.getCoordinates();
        var x = coords[0];
        var y = coords[1];
        
        // Bottom half of screen (y > 180)
        if (y > 180) {
            // Left side - YES
            if (x < 180) {
                var checkView = new checkPageView();
                var checkDelegate = new checkPageDelegate(checkView);
                WatchUi.pushView(checkView, checkDelegate, WatchUi.SLIDE_UP);
                return true;
            }
            // Right side - NO
            else {
                var chartView = new ChartView(null);
                var chartDelegate = new ChartDelegate();
                chartDelegate.setView(chartView);
                WatchUi.pushView(chartView, chartDelegate, WatchUi.SLIDE_DOWN);
                return true;
            }
        }
        
        return false;
    }
}
