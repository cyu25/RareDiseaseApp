import Toybox.Graphics;
import Toybox.WatchUi;
import Toybox.Lang;
import Toybox.Time;
import Toybox.Time.Gregorian;

class CalendarPageView extends WatchUi.View {

    // Current displayed month/year
    var currentYear as Number = 2025;
    var currentMonth as Number = 9;
    
    // Selected date
    var selectedDay as Number = 1;
    var selectedRow as Number = 0;
    var selectedCol as Number = 0;
    
    // Calendar grid (6 rows to handle all months)
    var calendarGrid as Array<Array<Number> >?;
    
    // Store which dates have survey data
    var datesWithData as Array<Number> = [5, 12, 18, 25];
    
 // Arrow button positions for touch detection
    var leftArrowX as Number = 105;
    var rightArrowX as Number = 285;

    function initialize() {
        View.initialize();
        
        // Get current date
        var today = Gregorian.info(Time.now(), Time.FORMAT_SHORT);
        currentYear = today.year;
        currentMonth = today.month;
        selectedDay = today.day;
        
        buildCalendarGrid();
        findSelectedPosition();
    }

    function onLayout(dc as Dc) as Void {
    }

    function onShow() as Void {
    }

    function onUpdate(dc as Dc) as Void {
        var width = dc.getWidth();
        var height = dc.getHeight();
        var centerX = width / 2;
        
        // White background
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_WHITE);
        dc.clear();
        
        // Draw all components
        drawTitle(dc, centerX);
        drawMonthYearHeader(dc, centerX);
        drawDayHeaders(dc, width);
        drawCalendarGrid(dc, width, height);
    }
    
    function drawTitle(dc as Dc, centerX as Number) as Void {
        // "Select a Date" in BLUE
        dc.setColor(Graphics.COLOR_BLUE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(centerX, 50, Graphics.FONT_TINY, "Select a Date", 
                    Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
    }
    
    function drawMonthYearHeader(dc as Dc, centerX as Number) as Void {
        var headerY = 83;
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_TRANSPARENT);
        
        // Month and Year in center
        var monthName = getMonthName(currentMonth);
        var monthYearText = monthName + " " + currentYear;
        dc.drawText(centerX, headerY, Graphics.FONT_TINY, monthYearText, 
                    Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        
        // Left arrow 
        dc.setColor(Graphics.COLOR_BLUE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(centerX - 100, headerY, Graphics.FONT_SMALL, "<", 
                    Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        
        // Right arrow 
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
        var cellHeight = 32;  // Slightly smaller to fit 5 weeks
        var startX = 25;
        var startY = 145;
        
        // Draw 5 weeks (rows 0-4)
        for (var row = 0; row < 5; row++) {
            if (row >= 6) {
                continue;
            }
            
            for (var col = 0; col < 7; col++) {
                var dayValue = calendarGrid[row][col];
                var x = startX + (col * cellWidth) + (cellWidth / 2);
                var y = startY + (row * cellHeight);
                
                // Only show current month days (skip negative and 100+ values)
                if (dayValue <= 0 || dayValue > 100) {
                    // Don't draw previous/next month days
                    continue;
                }
                
                var displayDay = dayValue;
                
                // Check if this cell is currently selected
                var isSelected = (row == selectedRow && col == selectedCol);
                
                // Draw selection box
                if (isSelected) {
                    dc.setColor(Graphics.COLOR_BLUE, Graphics.COLOR_BLACK);
                    dc.fillRoundedRectangle(x - 20, y - 14, 40, 30, 8);
                    dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
                } else {
                    dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_TRANSPARENT);
                }
                
                // Draw day number
                dc.drawText(x, y, Graphics.FONT_TINY, displayDay.toString(), 
                            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
            }
        }
    }
    
    // Build the calendar grid for current month
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
                    // Previous month - mark as negative (won't be displayed)
                    calendarGrid[row][col] = -(prevMonthDays - firstDay + cellIndex + 1);
                } else if (day <= daysInMonth) {
                    // Current month
                    calendarGrid[row][col] = day;
                    day++;
                } else {
                    // Next month - mark as 100+ (won't be displayed)
                    calendarGrid[row][col] = 100 + nextDay;
                    nextDay++;
                }
            }
        }
    }
    
    // Find the row/col position of selected day
    function findSelectedPosition() as Void {
        if (calendarGrid == null) {
            return;
        }
        for (var row = 0; row < 6; row++) {
            for (var col = 0; col < 7; col++) {
                if (calendarGrid[row][col] == selectedDay) {
                    selectedRow = row;
                    selectedCol = col;
                    return;
                }
            }
        }
        // Default to day 1 if not found
        selectedDay = 1;
        findSelectedPosition();
    }
    
    // Check if a date has survey data
    function dateHasData(day as Number) as Boolean {
        for (var i = 0; i < datesWithData.size(); i++) {
            if (datesWithData[i] == day) {
                return true;
            }
        }
        return false;
    }
    
    // Get month name
    function getMonthName(month as Number) as String {
        var months = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", 
                      "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"];
        return months[month - 1];
    }
    
    // Get days in month
    function getDaysInMonth(year as Number, month as Number) as Number {
        var days = [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31];
        if (month == 2 && ((year % 4 == 0 && year % 100 != 0) || year % 400 == 0)) {
            return 29;
        }
        return days[month - 1];
    }
    
    // Get first day of week (0 = Sunday)
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
        System.print("NEXT MONTH BE RUNNIN");
        currentMonth++;
        if (currentMonth > 12) {
            currentMonth = 1;
            currentYear++;
        }
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
        buildCalendarGrid();
        selectedDay = 1;
        findSelectedPosition();
        WatchUi.requestUpdate();
    }
    
    // Cycle to next day (UP button)
function nextDay() as Void {
    var daysInMonth = getDaysInMonth(currentYear, currentMonth);
    selectedDay++;
    if (selectedDay > daysInMonth) {
        selectedDay = 1;
    }
    findSelectedPosition();
    WatchUi.requestUpdate();
}
    
    // Get currently selected date info
    function getSelectedDate() as Dictionary {
        return {
            "day" => selectedDay,
            "month" => currentMonth,
            "year" => currentYear,
            "hasData" => dateHasData(selectedDay)
        };
    }
    
    // Format date as string
    function getSelectedDateString() as String {
        var monthName = getMonthName(currentMonth);
        return monthName + " " + selectedDay + ", " + currentYear;
    }

    function onHide() as Void {
    }
}