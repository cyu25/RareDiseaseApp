import Toybox.Application;
import Toybox.Lang;
import Toybox.WatchUi;

class app_designApp extends Application.AppBase {

    function initialize() {
        AppBase.initialize();
    }

    function onStart(state as Dictionary?) as Void {
    }

    function onStop(state as Dictionary?) as Void {
    }

    function getInitialView() {
        var view = new CalendarPageView();
        var delegate = new CalendarPageDelegate(view);
        return [view, delegate];
    }
}

function getApp() as app_designApp {
    return Application.getApp() as app_designApp;
}