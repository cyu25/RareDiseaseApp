import Toybox.Graphics;
import Toybox.Lang;
import Toybox.System;
import Toybox.WatchUi;

class app_designView extends WatchUi.View {
    
    function initialize() {
        View.initialize();
    }
    
    function onLayout(dc as Dc) as Void {
        setLayout(Rez.Layouts.WatchFace(dc));
    }
    
    function onShow() as Void {
    }
    
    function onUpdate(dc) {
        var clockTime = System.getClockTime();
        
        var greeting;
        if (clockTime.hour < 12) {
            greeting = "Good morning";
        } else if (clockTime.hour < 17) {
            greeting = "Good afternoon";
        } else {
            greeting = "Good evening";
        }
        
        var userName = "there!";
        var greetingText = Lang.format("$1$, \n$2$", [greeting, userName]);
        var timeText = Lang.format(
            "$1$:$2$",
            [clockTime.hour, clockTime.min.format("%02d")]
        );
        var questionText = "Ready to track?";
        
        var greetingView = View.findDrawableById("GreetingLabel") as Text;
        if (greetingView != null) {
            greetingView.setText(greetingText);
        }
        
        var timeView = View.findDrawableById("TimeLabel") as Text;
        if (timeView != null) {
            timeView.setText(timeText);
        }
        
        var questionView = View.findDrawableById("QuestionLabel") as Text;
        if (questionView != null) {
            questionView.setText(questionText);
        }
        
        View.onUpdate(dc);
        
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
            yesX, yesY, Graphics.FONT_MEDIUM, "YES",
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
            skipX, skipY, Graphics.FONT_MEDIUM, "SKIP",
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER
        );
    }
}

class app_designDelegate extends WatchUi.BehaviorDelegate {
    
    function initialize() {
        BehaviorDelegate.initialize();
    }

    function onTap(clickEvent as ClickEvent) as Lang.Boolean {
        var coords = clickEvent.getCoordinates();
        var x = coords[0];
        var y = coords[1];
        
        if (y > 180) {
            // Left side - YES -> go to symptom check page
            if (x < 180) {
                WatchUi.pushView(new YesPageView(), new YesPageDelegate(), WatchUi.SLIDE_UP);
                return true;
            }
            // Right side - SKIP -> go to weekly trends chart (current week)
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