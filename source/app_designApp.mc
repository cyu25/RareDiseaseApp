import Toybox.Application;
import Toybox.Lang;
import Toybox.WatchUi;
import Toybox.Application.Storage;
import Toybox.Time;
import Toybox.Time.Gregorian;

class app_designApp extends Application.AppBase {

    function initialize() {
        AppBase.initialize();
    }

    function onStart(state as Dictionary?) as Void {
    }

    function onStop(state as Dictionary?) as Void {
    }

    function getInitialView() {

        /*
        UNCOMMENT SURVEYSTORAGE if you want to delete the previous
        stored information!! otherwise it will keep track of what you have put before
        */
        SurveyStorage.clearAllData();
        var view = new app_designView();
        var delegate = new app_designDelegate();

        /*
        HOME PAGE / DASHBOARD if the survey has been completed already
        */
        if (SurveyStorage.hasCompletedToday()) {
        var homeView = new HomeView();
        return [homeView, new HomeDelegate()];
     }
        return [view, delegate];
    }
}


function getApp() as app_designApp {
    return Application.getApp() as app_designApp;
}


class SurveyStorage {

    static function clearAllData() as Void {
        
        // Clear completion marker
        Storage.deleteValue("lastSurveyDate");
        
        // Get all survey dates and delete them
        var dates = getAllSurveyDates();
        for (var i = 0; i < dates.size(); i++) {
            Storage.deleteValue("survey_" + dates[i]);
        }
        
        // Clear the dates list
        Storage.deleteValue("allSurveyDates");
        
        // Clear any old response data
        for (var i = 0; i < 100; i++) {
            Storage.deleteValue("response_" + i);
        }
        Storage.deleteValue("lastQuestionIndex");
        
    }
    
    // Check if survey has been completed today
    static function hasCompletedToday() as Boolean {
        var lastCompleted = Storage.getValue("lastSurveyDate");
        
        if (lastCompleted == null) {
            return false;
        }
        
        var today = getTodayString();
        var lastCompletedStr = lastCompleted as String;
        return lastCompletedStr.equals(today);
    }
    
    // Mark survey as completed for today
    static function markCompletedToday() as Void {
        var today = getTodayString();
        Storage.setValue("lastSurveyDate", today);
    }
    
    // Get today's date as string (YYYY-MM-DD)
    static function getTodayString() as String {
        var now = Time.now();
        var info = Gregorian.info(now, Time.FORMAT_SHORT);
        return info.year.format("%04d") + "-" + info.month.format("%02d") + "-" + info.day.format("%02d");
    }
    
    // Save survey responses with timestamp
    static function saveSurveyData(responses as Array<Number>, categories as Array<String>, questionCategories as Array<String>) as Void {
        var today = getTodayString();
        var timestamp = Time.now().value();
        
        // Save the survey data
        var surveyData = {
            "date" => today,
            "timestamp" => timestamp,
            "responses" => responses,
            "categories" => categories,
            "questionCategories" => questionCategories
        };
        
        // Store with date as key
        Storage.setValue("survey_" + today, surveyData);
        
        // Update list of all survey dates
        var storedDates = Storage.getValue("allSurveyDates");
        var allDates = [] as Array<String>;
        
        if (storedDates != null) {
            var tempDates = storedDates as Array;
            for (var i = 0; i < tempDates.size(); i++) {
                allDates.add(tempDates[i] as String);
            }
        }
        
        // Add today if not already in list
        var found = false;
        for (var i = 0; i < allDates.size(); i++) {
            if (allDates[i].equals(today)) {
                found = true;
                break;
            }
        }
        
        if (!found) {
            allDates.add(today);
            Storage.setValue("allSurveyDates", allDates);
        }
        
        // Mark as completed
        markCompletedToday();
    }
    
    // Get all survey dates
    static function getAllSurveyDates() as Array<String> {
        var storedDates = Storage.getValue("allSurveyDates");
        var allDates = [] as Array<String>;
        
        if (storedDates != null) {
            var tempDates = storedDates as Array;
            for (var i = 0; i < tempDates.size(); i++) {
                allDates.add(tempDates[i] as String);
            }
        }
        
        return allDates;
    }
    
    // Get survey data for a specific date
    static function getSurveyData(dateString as String) as Dictionary? {
        return Storage.getValue("survey_" + dateString) as Dictionary;
    }
    
    // Reset daily completion (for testing)
    static function resetDailyCompletion() as Void {
        Storage.deleteValue("lastSurveyDate");
    }
}