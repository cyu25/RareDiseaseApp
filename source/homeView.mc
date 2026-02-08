import Toybox.Application;
import Toybox.Lang;
import Toybox.WatchUi;
import Toybox.Graphics;
import Toybox.Time;

class HomeView extends WatchUi.View {
    function initialize() {
        View.initialize();
    }
    
    function onUpdate(dc) as Void {
        var width = dc.getWidth();
        var height = dc.getHeight();
        var cx = width / 2;
        var cy = height / 2;
        
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.clear();
        
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, 60, Graphics.FONT_MEDIUM, "Today's Survey", 
                    Graphics.TEXT_JUSTIFY_CENTER);
        
        dc.setColor(Graphics.COLOR_GREEN, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, cy - 20, Graphics.FONT_SMALL, "Complete!", 
                    Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, cy + 40, Graphics.FONT_XTINY, "Tap to view results", 
                    Graphics.TEXT_JUSTIFY_CENTER);
        
        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, cy + 70, Graphics.FONT_XTINY, "Swipe up for trends", 
                    Graphics.TEXT_JUSTIFY_CENTER);
    }
}

class HomeDelegate extends WatchUi.BehaviorDelegate {
    function initialize() {
        BehaviorDelegate.initialize();
    }
    
    function onTap(clickEvent as ClickEvent) as Boolean {
        var today = SurveyStorage.getTodayString();
        var surveyData = SurveyStorage.getSurveyData(today);
        
        if (surveyData != null) {
            var responses = surveyData["responses"] as Array<Number>;
            var categories = surveyData["categories"] as Array<String>;
            var questionCategories = surveyData["questionCategories"] as Array<String>;
            
            var percentageValues = calculateCategoryAverages(responses, categories, questionCategories);
            var timestamp = surveyData["timestamp"] as Number;
            var moment = new Time.Moment(timestamp);
            
            var spiderView = new SpiderDiagramView(categories, percentageValues, moment);
            WatchUi.pushView(spiderView, new SpiderDiagramDelegate(spiderView), WatchUi.SLIDE_LEFT);
            return true;
        }
        
        return false;
    }
    
    function onSwipe(evt as SwipeEvent) as Boolean {
        var direction = evt.getDirection();
        
        if (direction == WatchUi.SWIPE_UP) {
            // Go directly to weekly trends chart
            var chartView = new ChartView(null);
            var chartDelegate = new ChartDelegate();
            chartDelegate.setView(chartView);
            WatchUi.pushView(chartView, chartDelegate, WatchUi.SLIDE_UP);
            return true;
        }
        
        return false;
    }
    
    function onBack() as Boolean {
        System.exit();
    }

    function calculateCategoryAverages(responses as Array<Number>, categories as Array<String>, questionCategories as Array<String>) as Array<Number> {
        var percentageValues = new [categories.size()];
        
        for (var c = 0; c < categories.size(); c++) {
            var categoryName = categories[c] as String;
            var sum = 0.0;
            var count = 0;
            
            for (var i = 0; i < responses.size(); i++) {
                if (questionCategories[i].equals(categoryName)) {
                    sum += (responses[i].toFloat() / 4.0 * 100.0);
                    count++;
                }
            }
            
            percentageValues[c] = (count > 0) ? (sum / count).toNumber() : 0;
        }
        
        return percentageValues;
    }
}
