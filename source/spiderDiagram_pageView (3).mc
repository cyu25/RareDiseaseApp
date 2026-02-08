import Toybox.WatchUi;
import Toybox.Graphics;
import Toybox.Lang;
import Toybox.Math;
import Toybox.Time;

class SpiderDiagramView extends WatchUi.View {
    private var symptomLabels as Array<String>;
    private var symptomValues as Array<Number>;
    private var numSymptoms as Number;
    private var centerX as Float;
    private var centerY as Float;
    private var radius as Float;
    private var recordedDate as Time.Moment;
    
    function initialize(labels as Array<String>, symptomData as Array<Number>, dateRecorded as Time.Moment) {
        View.initialize();
        symptomLabels = labels;
        numSymptoms = labels.size();
        recordedDate = dateRecorded;
        centerX = 0.0;
        centerY = 0.0;
        radius = 0.0;
        symptomValues = symptomData;
    }
    
    function onUpdate(dc as Dc) as Void {
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.clear();
        var screenWidth = dc.getWidth();
        var screenHeight = dc.getHeight();
        centerX = screenWidth / 2.0;
        centerY = screenHeight / 2.0;
        radius = (screenWidth < screenHeight ? screenWidth : screenHeight) * 0.28;
        var dateInfo = Time.Gregorian.info(recordedDate, Time.FORMAT_SHORT);
        var monthNames = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"];
        var dateText = Lang.format("$1$ $2$, $3$", [monthNames[dateInfo.month - 1], dateInfo.day, dateInfo.year]);
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(centerX, 15, Graphics.FONT_XTINY, dateText, Graphics.TEXT_JUSTIFY_CENTER);
        drawGridCircles(dc);
        drawAxes(dc);
        drawSpiderPolygon(dc);
        drawLabels(dc);
    }
    function drawGridCircles(dc as Dc) as Void {
        dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_TRANSPARENT);
        for (var i = 1; i <= 3; i++) { dc.drawCircle(centerX, centerY, (radius * i) / 3); }
    }
    function drawAxes(dc as Dc) as Void {
        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
        var angleStep = (2 * Math.PI) / numSymptoms;
        for (var i = 0; i < numSymptoms; i++) {
            var angle = (i * angleStep) - (Math.PI / 2);
            dc.drawLine(centerX, centerY, centerX + (radius * Math.cos(angle)), centerY + (radius * Math.sin(angle)));
        }
    }
    function drawSpiderPolygon(dc as Dc) as Void {
        if (numSymptoms == 0) { return; }
        var angleStep = (2 * Math.PI) / numSymptoms;
        var points = new [numSymptoms];
        var xCoords = new [numSymptoms];
        var yCoords = new [numSymptoms];
        for (var i = 0; i < numSymptoms; i++) {
            var angle = (i * angleStep) - (Math.PI / 2);
            var vr = (radius * symptomValues[i]) / 100.0;
            points[i] = [centerX + (vr * Math.cos(angle)), centerY + (vr * Math.sin(angle))];
            xCoords[i] = points[i][0]; yCoords[i] = points[i][1];
        }
        dc.setColor(Graphics.COLOR_BLUE, Graphics.COLOR_TRANSPARENT);
        dc.fillPolygon(points);
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.setPenWidth(2);
        for (var i = 0; i < numSymptoms; i++) {
            var n = (i + 1) % numSymptoms;
            dc.drawLine(xCoords[i], yCoords[i], xCoords[n], yCoords[n]);
        }
        dc.setPenWidth(1);
        dc.setColor(Graphics.COLOR_YELLOW, Graphics.COLOR_TRANSPARENT);
        for (var i = 0; i < numSymptoms; i++) { dc.fillCircle(xCoords[i], yCoords[i], 3); }
    }
    function drawLabels(dc as Dc) as Void {
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        var angleStep = (2 * Math.PI) / numSymptoms;
        var labelRadius = radius + 25;
        for (var i = 0; i < numSymptoms; i++) {
            var angle = (i * angleStep) - (Math.PI / 2);
            var label = symptomLabels[i];
            if (label.equals("Cardiac dysautonomia")) { label = "Cardiac"; }
            else if (label.equals("Gastrointestinal")) { label = "GI"; }
            else if (label.equals("Urogential")) { label = "Uro"; }
            dc.drawText(centerX + (labelRadius * Math.cos(angle)), centerY + (labelRadius * Math.sin(angle)),
                        Graphics.FONT_XTINY, label, Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        }
    }
    public function getSymptomValues() as Array<Number> { return symptomValues; }
    public function getSymptomLabels() as Array<String> { return symptomLabels; }
}

class SpiderDiagramDelegate extends WatchUi.BehaviorDelegate {
    private var view as SpiderDiagramView;
    function initialize(v as SpiderDiagramView) { BehaviorDelegate.initialize(); view = v; }
    function onBack() as Lang.Boolean { WatchUi.popView(WatchUi.SLIDE_DOWN); return true; }
    function onSwipe(evt as SwipeEvent) as Lang.Boolean {
        if (evt.getDirection() == WatchUi.SWIPE_UP) {
            var cv = new ChartView(null);
            var cd = new ChartDelegate();
            cd.setView(cv);
            WatchUi.pushView(cv, cd, WatchUi.SLIDE_UP);
            return true;
        }
        return false;
    }
}

// =========================================================
// WEEKLY TRENDS CHART VIEW
// =========================================================
class ChartView extends WatchUi.View {
    private var weeklyData as Array<Array<Number> >;
    private var dayLabels as Array<String>;
    private var categoryLabels as Array<String>;
    private var selectedCategories as Array<Number>;
    private var weekOffset as Number;
    
    function initialize(targetDate as String?) {
        View.initialize();
        dayLabels = ["S", "M", "T", "W", "Th", "F", "S"];
        selectedCategories = [];
        categoryLabels = [];
        weeklyData = [];
        if (targetDate != null) { weekOffset = calculateWeekOffset(targetDate); }
        else { weekOffset = 0; }
        loadWeekData();
    }
    
    function calculateWeekOffset(dateStr as String) as Number {
        var tY = dateStr.substring(0, 4).toNumber();
        var tM = dateStr.substring(5, 7).toNumber();
        var tD = dateStr.substring(8, 10).toNumber();
        var now = Time.now();
        var ti = Time.Gregorian.info(now, Time.FORMAT_SHORT);
        var thisSun = new Time.Moment(now.value() - ((ti.day_of_week - 1) * 86400));
        var tOpt = { :year => tY, :month => tM, :day => tD, :hour => 12, :minute => 0, :second => 0 };
        var tMom = Time.Gregorian.moment(tOpt);
        var tInfo = Time.Gregorian.info(tMom, Time.FORMAT_SHORT);
        var tSun = new Time.Moment(tMom.value() - ((tInfo.day_of_week - 1) * 86400));
        var dw = (thisSun.value() - tSun.value()) / 86400 / 7;
        if (dw < 0) { dw = 0; }
        return dw;
    }

    function loadWeekData() as Void {
        var now = Time.now();
        var ti = Time.Gregorian.info(now, Time.FORMAT_SHORT);
        var sunMom = new Time.Moment(now.value() - (((ti.day_of_week - 1) + (weekOffset * 7)) * 86400));
        var allCats = [] as Array<String>;
        var daily = new [7];
        for (var d = 0; d < 7; d++) {
            var dm = new Time.Moment(sunMom.value() + (d * 86400));
            var di = Time.Gregorian.info(dm, Time.FORMAT_SHORT);
            var ds = di.year.format("%04d") + "-" + di.month.format("%02d") + "-" + di.day.format("%02d");
            var sd = SurveyStorage.getSurveyData(ds);
            daily[d] = sd;
            if (sd != null) {
                var cats = sd["categories"] as Array<String>;
                for (var c = 0; c < cats.size(); c++) {
                    var found = false;
                    for (var e = 0; e < allCats.size(); e++) { if (allCats[e].equals(cats[c])) { found = true; break; } }
                    if (!found) { allCats.add(cats[c]); }
                }
            }
        }
        categoryLabels = allCats;
        selectedCategories = [];
        var mx = allCats.size() < 3 ? allCats.size() : 3;
        for (var i = 0; i < mx; i++) { selectedCategories.add(i); }
        weeklyData = new [allCats.size()];
        for (var c = 0; c < allCats.size(); c++) {
            weeklyData[c] = new [7];
            var cn = allCats[c] as String;
            for (var d = 0; d < 7; d++) {
                weeklyData[c][d] = -1;
                var sd = daily[d];
                if (sd != null) {
                    var resp = sd["responses"] as Array<Number>;
                    var qc = sd["questionCategories"] as Array<String>;
                    var sum = 0.0; var cnt = 0;
                    for (var i = 0; i < resp.size(); i++) {
                        if (qc[i].equals(cn)) { sum += resp[i].toFloat(); cnt++; }
                    }
                    if (cnt > 0) { weeklyData[c][d] = (sum / cnt).toNumber(); }
                }
            }
        }
    }

    function onUpdate(dc as Dc) as Void {
        var W = dc.getWidth();
        var H = dc.getHeight();
        var cx = W / 2;
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.clear();

        // On a round screen, the usable width at a given y is limited by the circle.
        // For a 390x390 screen, the circle clips at the edges.
        // We need to keep all content within the safe zone.
        
        // Use percentage-based positioning for any screen size
        var titleY = (H * 12) / 100;       // ~47px on 390
        var weekY = (H * 17) / 100;        // ~66px on 390
        var pillY = (H * 22) / 100;        // ~86px on 390
        var chartTop = (H * 28) / 100;     // ~109px on 390
        var chartBottom = (H * 72) / 100;  // ~281px on 390
        var dayLabelY = (H * 75) / 100;    // ~293px on 390

        // For round screen: at titleY, how wide is the visible area?
        // width at y = 2 * sqrt(r^2 - (y - cy)^2) where r = W/2, cy = H/2
        // We'll use a safe chart margin that fits inside the circle
        var chartLeft = (W * 20) / 100;    // ~78px
        var chartRight = (W * 85) / 100;   // ~332px
        var chartWidth = chartRight - chartLeft;
        var chartHeight = chartBottom - chartTop;

        // ROW 1: Title
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, titleY, Graphics.FONT_XTINY, "Your Trends", Graphics.TEXT_JUSTIFY_CENTER);

        // ROW 2: < Week of Feb 8 >
        var sunLabel = getWeekSundayInfo();
        dc.drawText(cx, weekY, Graphics.FONT_XTINY, "Week of " + sunLabel, Graphics.TEXT_JUSTIFY_CENTER);
        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
        // Arrows positioned at safe x for round screen at this y
        var arrowInset = (W * 12) / 100; // ~47px from edge
        dc.drawText(arrowInset, weekY, Graphics.FONT_XTINY, "<", 
                    Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        dc.drawText(W - arrowInset, weekY, Graphics.FONT_XTINY, ">", 
                    Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);

        // ROW 3: Category pills
        drawCategoryPills(dc, cx, W, pillY);

        // Y-axis gridlines + labels
        for (var i = 0; i <= 4; i++) {
            var y = chartBottom - (i.toFloat() / 4.0 * chartHeight);
            dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_TRANSPARENT);
            dc.drawLine(chartLeft, y, chartRight, y);
            dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
            dc.drawText(chartLeft - 4, y, Graphics.FONT_XTINY, i.toString(), 
                        Graphics.TEXT_JUSTIFY_RIGHT | Graphics.TEXT_JUSTIFY_VCENTER);
        }

        // X-axis day labels
        var stepX = chartWidth.toFloat() / 6.0;
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        for (var d = 0; d < 7; d++) {
            var x = chartLeft + (d * stepX);
            dc.drawText(x, dayLabelY, Graphics.FONT_XTINY, dayLabels[d], Graphics.TEXT_JUSTIFY_CENTER);
        }

        // Data lines
        var lineColors = [Graphics.COLOR_BLUE, Graphics.COLOR_PURPLE, 0x00AAFF];
        for (var s = 0; s < selectedCategories.size(); s++) {
            var catIdx = selectedCategories[s] as Number;
            if (catIdx >= weeklyData.size()) { continue; }
            var catData = weeklyData[catIdx] as Array<Number>;
            dc.setColor(lineColors[s % lineColors.size()], Graphics.COLOR_TRANSPARENT);
            dc.setPenWidth(2);
            var pX = -1; var pY = -1;
            for (var d = 0; d < 7; d++) {
                if (catData[d] < 0) { pX = -1; continue; }
                var x = chartLeft + (d * stepX);
                var y = chartBottom - (catData[d].toFloat() / 4.0 * chartHeight);
                if (pX >= 0) { dc.drawLine(pX, pY, x, y); }
                dc.fillCircle(x, y, 4);
                pX = x; pY = y;
            }
            dc.setPenWidth(1);
        }
        
        if (categoryLabels.size() == 0) {
            dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
            dc.drawText(cx, H / 2, Graphics.FONT_XTINY, "No data this week", Graphics.TEXT_JUSTIFY_CENTER);
        }
    }

    function drawCategoryPills(dc as Dc, cx as Number, screenW as Number, pillY as Number) as Void {
        var pillHeight = 16;
        var spacing = 4;
        var totalPills = categoryLabels.size() < 3 ? categoryLabels.size() : 3;
        if (totalPills == 0) { return; }
        // Calculate safe width at this y on round screen
        var safeWidth = screenW - (screenW * 30 / 100); // 70% of screen width
        var pillWidth = (safeWidth - (totalPills - 1) * spacing) / totalPills;
        if (pillWidth > 75) { pillWidth = 75; }
        var totalWidth = totalPills * pillWidth + (totalPills - 1) * spacing;
        var startX = cx - totalWidth / 2;
        var lineColors = [Graphics.COLOR_BLUE, Graphics.COLOR_PURPLE, 0x00AAFF];
        for (var i = 0; i < totalPills; i++) {
            var pX = startX + i * (pillWidth + spacing);
            var isSel = false;
            for (var s = 0; s < selectedCategories.size(); s++) { if (selectedCategories[s] == i) { isSel = true; break; } }
            if (isSel) {
                dc.setColor(lineColors[i % lineColors.size()], Graphics.COLOR_TRANSPARENT);
                dc.fillRoundedRectangle(pX, pillY, pillWidth, pillHeight, 8);
                dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
            } else {
                dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_TRANSPARENT);
                dc.drawRoundedRectangle(pX, pillY, pillWidth, pillHeight, 8);
                dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
            }
            var label = categoryLabels[i];
            if (label.equals("Cardiac dysautonomia")) { label = "Cardiac"; }
            else if (label.equals("Gastrointestinal")) { label = "GI"; }
            else if (label.equals("Urogential")) { label = "Uro"; }
            else if (label.equals("Depression")) { label = "Depress"; }
            else if (label.length() > 7) { label = label.substring(0, 7); }
            dc.drawText(pX + pillWidth / 2, pillY + pillHeight / 2, Graphics.FONT_XTINY,
                        label, Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        }
    }

    function getWeekSundayInfo() as String {
        var now = Time.now();
        var ti = Time.Gregorian.info(now, Time.FORMAT_SHORT);
        var sunMom = new Time.Moment(now.value() - (((ti.day_of_week - 1) + (weekOffset * 7)) * 86400));
        var info = Time.Gregorian.info(sunMom, Time.FORMAT_SHORT);
        var mn = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"];
        return mn[info.month - 1] + " " + info.day;
    }

    function previousWeek() as Void { weekOffset++; loadWeekData(); WatchUi.requestUpdate(); }
    function nextWeek() as Void { if (weekOffset > 0) { weekOffset--; loadWeekData(); WatchUi.requestUpdate(); } }
    function toggleCategory(index as Number) as Void {
        for (var i = 0; i < selectedCategories.size(); i++) {
            if (selectedCategories[i] == index) {
                var ns = [] as Array<Number>;
                for (var j = 0; j < selectedCategories.size(); j++) { if (j != i) { ns.add(selectedCategories[j]); } }
                selectedCategories = ns;
                WatchUi.requestUpdate();
                return;
            }
        }
        if (selectedCategories.size() < 3) { selectedCategories.add(index); WatchUi.requestUpdate(); }
    }
}

class ChartDelegate extends WatchUi.BehaviorDelegate {
    private var chartView as ChartView?;
    function initialize() { BehaviorDelegate.initialize(); chartView = null; }
    function setView(v as ChartView) as Void { chartView = v; }
    function onTap(clickEvent as ClickEvent) as Boolean {
        if (chartView == null) { return false; }
        var coords = clickEvent.getCoordinates();
        var x = coords[0]; var y = coords[1];
        // Use percentages matching onUpdate layout
        // Week arrows zone: weekY area (17% of screen)
        if (y >= 50 && y <= 85) {
            if (x < 80) { chartView.previousWeek(); return true; }
            if (x > 310) { chartView.nextWeek(); return true; }
        }
        // Category pills zone: pillY area (22% of screen)
        if (y >= 80 && y <= 115) {
            // Simplified: left third / middle third / right third of pill area
            var screenW = 390;
            var cx = screenW / 2;
            var safeWidth = screenW - (screenW * 30 / 100);
            var spacing = 4;
            var totalPills = 3;
            var pillWidth = (safeWidth - (totalPills - 1) * spacing) / totalPills;
            if (pillWidth > 75) { pillWidth = 75; }
            var totalWidth = totalPills * pillWidth + (totalPills - 1) * spacing;
            var startX = cx - totalWidth / 2;
            for (var i = 0; i < totalPills; i++) {
                var pX = startX + i * (pillWidth + spacing);
                if (x >= pX && x <= pX + pillWidth) { chartView.toggleCategory(i); return true; }
            }
        }
        return false;
    }
    function onBack() as Lang.Boolean { WatchUi.popView(WatchUi.SLIDE_DOWN); return true; }
    function onSwipe(evt as SwipeEvent) as Lang.Boolean {
        if (evt.getDirection() == WatchUi.SWIPE_UP) {
            var cv = new CalendarPageView();
            WatchUi.pushView(cv, new CalendarPageDelegate(cv), WatchUi.SLIDE_UP);
            return true;
        }
        return false;
    }
}
