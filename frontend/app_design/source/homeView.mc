import Toybox.Application;
import Toybox.Lang;
import Toybox.WatchUi;
import Toybox.Graphics;
import Toybox.Time;

class HomeView extends WatchUi.View {
    private var _resetButtonY as Number = 0;
    private var _resetButtonHeight as Number = 30;
    
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
        
        dc.setColor(Graphics.COLOR_BLUE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, cy - 20, Graphics.FONT_SMALL, "Complete!", 
                    Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        
        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, cy + 40, Graphics.FONT_XTINY, "Swipe up for trends", 
                    Graphics.TEXT_JUSTIFY_CENTER);
    
        dc.setColor(Graphics.COLOR_ORANGE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, cy + 95, Graphics.FONT_XTINY, "Tap to Reset", 
                    Graphics.TEXT_JUSTIFY_CENTER);
    }
    
    function getResetButtonY() as Number {
        return _resetButtonY;
    }
    
    function getResetButtonHeight() as Number {
        return _resetButtonHeight;
    }
}

class HomeDelegate extends WatchUi.BehaviorDelegate {
    private var _view as HomeView;
    
    function initialize(view as HomeView) {
        BehaviorDelegate.initialize();
        _view = view;
    }
    
    function onTap(clickEvent as ClickEvent) as Boolean {
    
        // Show confirmation dialog
        var dialog = new WatchUi.Confirmation("Reset today's survey?");
        WatchUi.pushView(dialog, new ResetConfirmationDelegate(), WatchUi.SLIDE_IMMEDIATE);
        return true;
        
    }
    
    function onSwipe(evt as SwipeEvent) as Boolean {

        var today = SurveyStorage.getTodayString();
        var surveyData = SurveyStorage.getSurveyData(today);
        
        if (surveyData != null) {
            var responses = surveyData["responses"] as Array<Number>;
            var activeCategories = surveyData["categories"] as Array<String>;
            var questionCategories = surveyData["questionCategories"] as Array<String>;
            
            var symptomLabels = ["NMSK", "Pain", "Fatigue", "Gastrointestinal", "Cardiac dysautonomia", "Urogential", "Anxiety", "Depression"];
            var percentageValues = new [8];
            for (var c = 0; c < 8; c++) {
                var categoryName = symptomLabels[c] as String;
                var isActive = false;
                for (var j = 0; j < activeCategories.size(); j++) {
                    if (categoryName.equals(activeCategories[j])) {
                        isActive = true;
                        break;
                    }
                }
                if (!isActive) {
                    percentageValues[c] = 0;
                } else {
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
            }
            var timestamp = surveyData["timestamp"] as Number;
            var moment = new Time.Moment(timestamp);
            var spiderView = new SpiderDiagramView(symptomLabels, percentageValues, moment);
            WatchUi.pushView(spiderView, new SpiderDiagramDelegate(spiderView), WatchUi.SLIDE_LEFT);
            return true;
        }

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
        return true;
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

class ResetConfirmationDelegate extends WatchUi.ConfirmationDelegate {
    function initialize() {
        ConfirmationDelegate.initialize();
    }
    
    function onResponse(response) as Boolean {
    if (response == WatchUi.CONFIRM_YES) {
        SurveyStorage.resetDailyCompletion();

        WatchUi.popView(WatchUi.SLIDE_IMMEDIATE);
        
        // Go to the main survey view
        var view = new app_designView();
        var delegate = new app_designDelegate();
        WatchUi.switchToView(view, delegate, WatchUi.SLIDE_IMMEDIATE);
        return true;
    } else {
        var homeView = new HomeView();
        WatchUi.switchToView(homeView, new HomeDelegate(homeView), WatchUi.SLIDE_IMMEDIATE);
        return true;
    }
}
}