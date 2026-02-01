import Toybox.Lang;
import Toybox.WatchUi;
import Toybox.System;

class CalendarPageDelegate extends WatchUi.BehaviorDelegate {

    var calendarView as CalendarPageView;

    function initialize(view as CalendarPageView) {
        BehaviorDelegate.initialize();
        calendarView = view;
    }

    // UP button - cycle to next day
    function onPreviousPage() as Boolean {
        calendarView.nextDay();
        return true;
    }

    // DOWN button - select the date
    function onNextPage() as Boolean {
        return onSelect();
    }

    // SELECT/ENTER button - select the date
    function onSelect() as Boolean {
        var dateInfo = calendarView.getSelectedDate();
        var dateString = calendarView.getSelectedDateString();
        var hasData = dateInfo["hasData"] as Boolean;
        
        WatchUi.pushView(
            new DateResultView(dateString, hasData),
            new DateResultDelegate(),
            WatchUi.SLIDE_LEFT
        );
        
        return true;
    }

    // BACK button
    function onBack() as Boolean {
        WatchUi.popView(WatchUi.SLIDE_RIGHT);
        return true;
    }
}