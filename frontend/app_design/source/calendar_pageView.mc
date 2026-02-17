import Toybox.Graphics;
import Toybox.WatchUi;
import Toybox.Lang;
import Toybox.Time;
import Toybox.Time.Gregorian;

class CalendarPageView extends WatchUi.View {
    var currentYear as Number = 2025;
    var currentMonth as Number = 9;
    
    var selectedDay as Number = 1;
    var selectedRow as Number = 0;
    var selectedCol as Number = 0;
    
    var calendarGrid as Array<Array<Number> >?;
    var datesWithData as Array<Number> = [];
    
    function initialize() {
        View.initialize();
        
        var today = Gregorian.info(Time.now(), Time.FORMAT_SHORT);
        currentYear = today.year;
        currentMonth = today.month;
        selectedDay = today.day;
        
        updateDatesWithData();
        buildCalendarGrid();
        findSelectedPosition();
    }

    function splitDateString(dateStr as String) as Array<Number> {
        var year = dateStr.substring(0, 4).toNumber();
        var month = dateStr.substring(5, 7).toNumber();
        var day = dateStr.substring(8, 10).toNumber();
        return [year, month, day];
    }
    
    function onUpdate(dc as Dc) as Void {
        var width = dc.getWidth();
        var height = dc.getHeight();
        var centerX = width / 2;
        
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_WHITE);
        dc.clear();
        
        drawTitle(dc, centerX);
        drawMonthYearHeader(dc, centerX);
        drawDayHeaders(dc, width);
        drawCalendarGrid(dc, width, height);
        drawPageIndicators(dc, dc.getHeight(), 3);
    }
    
    function drawPageIndicators(dc as Dc, screenH as Number, currentPage as Number) as Void {
        var dotRadius = 4;
        var dotSpacing = 15;
        var x = 20; // Left margin
        var startY = (screenH / 2) - dotSpacing; // Center vertically
        
        for (var i = 0; i < 4; i++) {
            var y = startY + (i * dotSpacing);
            
            if (i == currentPage) {
                // Current page - filled dot
                dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_TRANSPARENT);
                dc.fillCircle(x, y, dotRadius);
            } else {
                // Other pages - outline dot
                dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_TRANSPARENT);
                dc.drawCircle(x, y, dotRadius);
            }
        }
    }

    function drawTitle(dc as Dc, centerX as Number) as Void {
        dc.setColor(Graphics.COLOR_BLUE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(centerX, 50, Graphics.FONT_TINY, "Select a Date", 
                    Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
    }
    
    function drawMonthYearHeader(dc as Dc, centerX as Number) as Void {
        var headerY = 83;
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_TRANSPARENT);
        
        var monthName = getMonthName(currentMonth);
        var monthYearText = monthName + " " + currentYear;
        dc.drawText(centerX, headerY, Graphics.FONT_TINY, monthYearText, 
                    Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        
        dc.setColor(Graphics.COLOR_BLUE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(centerX - 100, headerY, Graphics.FONT_SMALL, "<", 
                    Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        dc.drawText(centerX + 100, headerY, Graphics.FONT_SMALL, ">", 
                    Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
    }
    
    function drawDayHeaders(dc as Dc, width as Number) as Void {
        var dayNames = ["Su", "Mo", "Tu", "We", "Th", "Fr", "Sa"];
        var headerY = 115;
        var cellWidth = (width - 40) / 7;
        var startX = 25;
        
        dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_TRANSPARENT);
        
        for (var i = 0; i < 7; i++) {
            var x = startX + (i * cellWidth) + (cellWidth / 2);
            dc.drawText(x, headerY, Graphics.FONT_XTINY, dayNames[i], 
                        Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        }
    }
    
    function drawCalendarGrid(dc as Dc, width as Number, height as Number) as Void {
        if (calendarGrid == null) {
            return;
        }
        
        var cellWidth = (width - 40) / 7;
        var cellHeight = 32;
        var startX = 25;
        var startY = 145;
        
        for (var row = 0; row < 5; row++) {
            if (row >= 6) { continue; }
            
            for (var col = 0; col < 7; col++) {
                var dayValue = calendarGrid[row][col];
                var x = startX + (col * cellWidth) + (cellWidth / 2);
                var y = startY + (row * cellHeight);
                
                if (dayValue <= 0 || dayValue > 100) { continue; }
                
                var displayDay = dayValue;
                var isSelected = (row == selectedRow && col == selectedCol);
                var hasData = dateHasData(dayValue);
                
                if (isSelected) {
                    dc.setColor(Graphics.COLOR_BLUE, Graphics.COLOR_BLACK);
                    dc.fillRoundedRectangle(x - 20, y - 14, 40, 30, 8);
                    dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
                } else if (hasData) {
                    // Highlight dates that have survey data with a subtle indicator
                    dc.setColor(0x336699, Graphics.COLOR_TRANSPARENT);
                    dc.fillCircle(x, y + 12, 2);
                    dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_TRANSPARENT);
                } else {
                    dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_TRANSPARENT);
                }
                
                dc.drawText(x, y, Graphics.FONT_TINY, displayDay.toString(), 
                            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
            }
        }
    }
    
    function buildCalendarGrid() as Void {
        calendarGrid = new Array<Array<Number> >[6];
        
        var firstDay = getFirstDayOfWeek(currentYear, currentMonth);
        var daysInMonth = getDaysInMonth(currentYear, currentMonth);
        var prevMonth = currentMonth == 1 ? 12 : currentMonth - 1;
        var prevYear = currentMonth == 1 ? currentYear - 1 : currentYear;
        var prevMonthDays = getDaysInMonth(prevYear, prevMonth);
        
        var day = 1;
        var nextDay = 1;
        
        for (var row = 0; row < 6; row++) {
            calendarGrid[row] = new Array<Number>[7];
            for (var col = 0; col < 7; col++) {
                var cellIndex = row * 7 + col;
                
                if (cellIndex < firstDay) {
                    calendarGrid[row][col] = -(prevMonthDays - firstDay + cellIndex + 1);
                } else if (day <= daysInMonth) {
                    calendarGrid[row][col] = day;
                    day++;
                } else {
                    calendarGrid[row][col] = 100 + nextDay;
                    nextDay++;
                }
            }
        }
    }
    
    function findSelectedPosition() as Void {
        if (calendarGrid == null) { return; }
        for (var row = 0; row < 6; row++) {
            for (var col = 0; col < 7; col++) {
                if (calendarGrid[row][col] == selectedDay) {
                    selectedRow = row;
                    selectedCol = col;
                    return;
                }
            }
        }
        selectedDay = 1;
        findSelectedPosition();
    }
    
    function dateHasData(day as Number) as Boolean {
        for (var i = 0; i < datesWithData.size(); i++) {
            if (datesWithData[i] == day) {
                return true;
            }
        }
        return false;
    }
    
    function getMonthName(month as Number) as String {
        var months = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", 
                      "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"];
        return months[month - 1];
    }
    
    function getDaysInMonth(year as Number, month as Number) as Number {
        var days = [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31];
        if (month == 2 && ((year % 4 == 0 && year % 100 != 0) || year % 400 == 0)) {
            return 29;
        }
        return days[month - 1];
    }
    
    function getFirstDayOfWeek(year as Number, month as Number) as Number {
        var y = year;
        var m = month;
        if (m < 3) {
            m += 12;
            y -= 1;
        }
        var k = y % 100;
        var j = y / 100;
        var day = (1 + (13 * (m + 1)) / 5 + k + k / 4 + j / 4 - 2 * j) % 7;
        return (day + 6) % 7;
    }
    
    function nextMonth() as Void {
        currentMonth++;
        if (currentMonth > 12) {
            currentMonth = 1;
            currentYear++;
        }
        updateDatesWithData();
        buildCalendarGrid();
        selectedDay = 1;
        findSelectedPosition();
        WatchUi.requestUpdate();
    }

    function previousMonth() as Void {
        currentMonth--;
        if (currentMonth < 1) {
            currentMonth = 12;
            currentYear--;
        }
        updateDatesWithData();
        buildCalendarGrid();
        selectedDay = 1;
        findSelectedPosition();
        WatchUi.requestUpdate();
    }

    function updateDatesWithData() as Void {
        var allDates = SurveyStorage.getAllSurveyDates();
        datesWithData = [];
        
        for (var i = 0; i < allDates.size(); i++) {
            var dateStr = allDates[i] as String;
            var parts = splitDateString(dateStr);
            if (parts[0] == currentYear && parts[1] == currentMonth) {
                datesWithData.add(parts[2]);
            }
        }
    }
    
    function nextDay() as Void {
        var daysInMonth = getDaysInMonth(currentYear, currentMonth);
        selectedDay++;
        if (selectedDay > daysInMonth) {
            selectedDay = 1;
        }
        findSelectedPosition();
        WatchUi.requestUpdate();
    }
    
    function getSelectedDate() as Dictionary {
        return {
            "day" => selectedDay,
            "month" => currentMonth,
            "year" => currentYear,
            "hasData" => dateHasData(selectedDay)
        };
    }
    
    function getSelectedDateString() as String {
        var monthName = getMonthName(currentMonth);
        return monthName + " " + selectedDay + ", " + currentYear;
    }

    function getSelectedDateStringFormatted() as String {
    return currentYear.format("%04d") + "-" + currentMonth.format("%02d") + "-" + selectedDay.format("%02d");
}
    
    function getDayAtPosition(x as Number, y as Number) as Number {
        if (calendarGrid == null) { return -1; }
        
        var width = 360;
        var cellWidth = (width - 40) / 7;
        var cellHeight = 32;
        var startX = 25;
        var startY = 145;
        
        if (y < startY || y > startY + (5 * cellHeight)) { return -1; }
        
        var col = (x - startX) / cellWidth;
        var row = (y - startY) / cellHeight;
        
        if (col < 0 || col >= 7 || row < 0 || row >= 5) { return -1; }
        
        var dayValue = calendarGrid[row][col];
        
        if (dayValue <= 0 || dayValue > 100) { return -1; }
        
        return dayValue;
    }

    function previousDay() as Void {
    selectedDay--;
    if (selectedDay < 1) {
        // Go to previous month
        currentMonth--;
        if (currentMonth < 1) {
            currentMonth = 12;
            currentYear--;
        }
        updateDatesWithData();
        buildCalendarGrid();
        selectedDay = getDaysInMonth(currentYear, currentMonth);
    }
    findSelectedPosition();
    WatchUi.requestUpdate();
}
}

class CalendarPageDelegate extends WatchUi.InputDelegate {
    var calendarView as CalendarPageView;
    
    function initialize(view as CalendarPageView) {
        InputDelegate.initialize();
        calendarView = view;
    }
    
    function onTap(clickEvent as ClickEvent) as Boolean {
        var coords = clickEvent.getCoordinates();
        var x = coords[0];
        var y = coords[1];
        
        // Check left arrow
        if (x >= 50 && x <= 110 && y >= 53 && y <= 113) {
            calendarView.previousMonth();
            return true;
        }
        
        // Check right arrow
        if (x >= 250 && x <= 310 && y >= 53 && y <= 113) {
            calendarView.nextMonth();
            return true;
        }
        return false;
    }
    function onSwipe(swipeEvent as SwipeEvent) as Boolean {
        var direction = swipeEvent.getDirection();
        
        if (direction == WatchUi.SWIPE_UP) {
            calendarView.nextDay();
            return true;
        }

        if (direction == WatchUi.SWIPE_DOWN) {
            calendarView.previousDay();
            return true;
        }
        
        return false;
    }

    
    
    function onKey(keyEvent as KeyEvent) as Boolean {
        
        var key = keyEvent.getKey();
        if (key == WatchUi.KEY_ENTER) {
            
            var dateInfo = calendarView.getSelectedDate();
            var dateString = calendarView.getSelectedDateStringFormatted();
            var nodateString = calendarView.getSelectedDateString();
            var hasData = dateInfo["hasData"] as Boolean;
            
            if (hasData) {
                var surveyData = SurveyStorage.getSurveyData(dateString);
                
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
            }
            System.println("Showing 'no data' view");
            WatchUi.pushView(
                new DateResultView(nodateString, hasData),
                new DateResultDelegate(),
                WatchUi.SLIDE_LEFT
            );
            return true;
        }
        return false;
    }
    function onBack() as Boolean {
        WatchUi.popView(WatchUi.SLIDE_RIGHT);
        return true;
    }
}