import Toybox.WatchUi;
import Toybox.Graphics;
import Toybox.Lang;
import Toybox.Communications;
import Toybox.System;

// -------------------------
// HRV ROLLING AVERAGE SCORE PAGE (Today's Score)
// Appears after spider diagram; swipe up to go to trends screen.
// -------------------------
class scorePageView extends WatchUi.View {

    private var hrvAverage as Float?;
    private var hrvPercentile10 as Float?;
    private var hrvPercentile90 as Float?;
    private var daysIncluded as Number;
    private var isLoading as Boolean;
    private var errorMessage as String?;

    private const BACKEND_URL = "https://your-ngrok-url.ngrok-free.dev/hrv/rolling21";

    function initialize() {
        View.initialize();
        hrvAverage = null;
        hrvPercentile10 = null;
        hrvPercentile90 = null;
        daysIncluded = 0;
        isLoading = true;
        errorMessage = null;
        loadHRVData();
    }

    function loadHRVData() as Void {
        isLoading = true;
        errorMessage = null;
        WatchUi.requestUpdate();
        var options = {
            :method => Communications.HTTP_REQUEST_METHOD_GET,
            :responseType => Communications.HTTP_RESPONSE_CONTENT_TYPE_JSON
        };
        Communications.makeWebRequest(
            BACKEND_URL,
            null,
            options,
            method(:onHRVDataReceived)
        );
    }

    function onHRVDataReceived(responseCode as Number, data as Dictionary?) as Void {
        isLoading = false;
        if (responseCode == 200 && data != null) {
            if (data.hasKey("average") && data.get("average") != null) {
                hrvAverage = data.get("average") as Float;
            }
            if (data.hasKey("percentile10") && data.get("percentile10") != null) {
                hrvPercentile10 = data.get("percentile10") as Float;
            }
            if (data.hasKey("percentile90") && data.get("percentile90") != null) {
                hrvPercentile90 = data.get("percentile90") as Float;
            }
            if (data.hasKey("daysIncluded")) {
                daysIncluded = data.get("daysIncluded") as Number;
            }
            errorMessage = null;
        } else {
            if (data != null && data.hasKey("error")) {
                errorMessage = data.get("error") as String;
            } else {
                errorMessage = "Failed to load HRV data";
            }
            hrvAverage = null;
            hrvPercentile10 = null;
            hrvPercentile90 = null;
        }
        WatchUi.requestUpdate();
    }

    function onUpdate(dc as Dc) as Void {
        var screenW = dc.getWidth();
        var screenH = dc.getHeight();
        var cx = screenW / 2;
        var cy = screenH / 2;
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.clear();
        var r = (screenW < screenH ? screenW : screenH) / 2 - 12;

        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, cy - r + 20, Graphics.FONT_XTINY, "Today's Score:", Graphics.TEXT_JUSTIFY_CENTER);
        

        if (isLoading) {
            dc.drawText(cx, cy, Graphics.FONT_SMALL, "Loading...", Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        } else if (errorMessage != null) {
            dc.setColor(Graphics.COLOR_ORANGE, Graphics.COLOR_TRANSPARENT);
            dc.drawText(cx, cy - 20, Graphics.FONT_XTINY, "Error", Graphics.TEXT_JUSTIFY_CENTER);
            dc.drawText(cx, cy + 10, Graphics.FONT_XTINY, errorMessage, Graphics.TEXT_JUSTIFY_CENTER);
        } else if (hrvAverage != null) {
            dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
            var avgText = hrvAverage.format("%.1f");
            dc.drawText(cx, cy - 30, Graphics.FONT_NUMBER_HOT, avgText, Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
            dc.drawText(cx, cy + 10, Graphics.FONT_XTINY, "Average", Graphics.TEXT_JUSTIFY_CENTER);
            if (hrvPercentile10 != null && hrvPercentile90 != null) {
                var rangeY = cy + r - 80;
                dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
                dc.drawText(cx, rangeY, Graphics.FONT_XTINY, "Range (10th-90th)", Graphics.TEXT_JUSTIFY_CENTER);
                var rangeText = hrvPercentile10.format("%.1f") + " - " + hrvPercentile90.format("%.1f");
                dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
                dc.drawText(cx, rangeY + 18, Graphics.FONT_XTINY, rangeText, Graphics.TEXT_JUSTIFY_CENTER);
            }
            dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_TRANSPARENT);
            dc.drawText(cx, cy + r - 40, Graphics.FONT_XTINY, daysIncluded.toString() + " days", Graphics.TEXT_JUSTIFY_CENTER);
        } else {
            dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
            dc.drawText(cx, cy, Graphics.FONT_SMALL, "No HRV data", Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        }
    }
}

class ScorePageDelegate extends WatchUi.BehaviorDelegate {
    private var view as scorePageView;

    function initialize(v as scorePageView) {
        BehaviorDelegate.initialize();
        view = v;
    }

    function onSelect() as Boolean {
        view.loadHRVData();
        return true;
    }

    function onBack() as Boolean {
        WatchUi.popView(WatchUi.SLIDE_DOWN);
        return true;
    }

    function onSwipe(evt as SwipeEvent) as Boolean {
        var direction = evt.getDirection();
        if (direction == WatchUi.SWIPE_UP) {
            var chartView = new ChartView(null);
            var chartDelegate = new ChartDelegate();
            chartDelegate.setView(chartView);
            WatchUi.pushView(chartView, chartDelegate, WatchUi.SLIDE_UP);
        }
        return false;
    }
}
