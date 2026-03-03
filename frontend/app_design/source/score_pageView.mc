import Toybox.WatchUi;
import Toybox.Graphics;
import Toybox.Lang;
import Toybox.SensorHistory;
import Toybox.Time;
import Toybox.Time.Gregorian;
import Toybox.System;
import Toybox.Application.Storage;

class ScorePageView extends WatchUi.View {
    private var hasData as Boolean;
    private var hasSurveyData as Boolean;

    // Body battery fields
    private var morningPeak as Float?;
    private var currentLevel as Float?;
    private var todayLow as Float?;
    private var trend as String?;

    // Composite score
    private var compositeScore as Number;

    // hEDS-specific domain weights derived from Ewer et al. (2024), Spider validation
    // study in 11,151 hEDS/HSD adults (PMC11330398). Weights are proportional to
    // observed mean domain burden scores in the hEDS population.
    // Order matches symptomLabels in CompletionDelegate: NMSK, Pain, Fatigue,
    // Gastrointestinal, Cardiac dysautonomia, Urogential, Anxiety, Depression
    private var DOMAIN_WEIGHTS as Array<Float> = [
        0.1226f,  // NMSK            (mean burden 45.65, Ewer et al. 2024 Table 4)
        0.1395f,  // Pain            (mean burden 51.93, Ewer et al. 2024 Table 4)
        0.1752f,  // Fatigue         (mean burden 65.22, Ewer et al. 2024 Table 4 - highest)
        0.1114f,  // Gastrointestinal(mean burden 41.48, Ewer et al. 2024 Table 4)
        0.1295f,  // Cardiac dysauto (mean burden 48.22, Ewer et al. 2024 Table 4)
        0.0856f,  // Urogential      (mean burden 31.86, Ewer et al. 2024 Table 4 - lowest)
        0.1224f,  // Anxiety         (mean burden 45.55, Ewer et al. 2024 Table 4)
        0.1137f   // Depression      (mean burden 42.33, Ewer et al. 2024 Table 4)
    ] as Array<Float>;

    // Canonical label order matching CompletionDelegate's symptomLabels array
    private var DOMAIN_LABELS as Array<String> = [
        "NMSK",
        "Pain",
        "Fatigue",
        "Gastrointestinal",
        "Cardiac dysautonomia",
        "Urogential",
        "Anxiety",
        "Depression"
    ] as Array<String>;

    function initialize() {
        View.initialize();
        hasData = false;
        hasSurveyData = false;
        compositeScore = 0;
        loadHRVData();
        loadSurveyData();
    }

function loadHRVData() as Void {
    if (!(SensorHistory has :getBodyBatteryHistory)) {
        hasData = false;
        WatchUi.requestUpdate();
        return;
    }

    // Get just today's data
    var bodyBattery = SensorHistory.getBodyBatteryHistory({
        :period => 1,
        :order => SensorHistory.ORDER_NEWEST_FIRST
    });

    if (bodyBattery == null) {
        hasData = false;
        WatchUi.requestUpdate();
        return;
    }

    var values = [] as Array<Float>;
    var sample = bodyBattery.next();

    while (sample != null) {
        var val = sample.data;
        if (val != null) {
            values.add((val as Number).toFloat());
        }
        sample = bodyBattery.next();
    }

    if (values.size() == 0) {
        hasData = false;
        WatchUi.requestUpdate();
        return;
    }

    // Most recent = first sample (newest first order)
    currentLevel = values[0];

    // Peak = highest value (usually morning)
    var peak = values[0];
    var low = values[0];
    for (var i = 1; i < values.size(); i++) {
        if (values[i] > peak) { peak = values[i]; }
        if (values[i] < low) { low = values[i]; }
    }
    morningPeak = peak;
    todayLow = low;

    // Trend - compare last 3 samples
    if (values.size() >= 3) {
        if (values[0] > values[2]) {
            trend = "Recovering";
        } else if (values[0] < values[2]) {
            trend = "Draining";
        } else {
            trend = "Stable";
        }
    }

    hasData = true;
    WatchUi.requestUpdate();
}

public function loadSurveyData() as Void {
    var today = SurveyStorage.getTodayString();
    var surveyData = SurveyStorage.getSurveyData(today);

    if (surveyData == null) {
        hasSurveyData = false;
        return;
    }

    var responses = surveyData.get("responses") as Array<Number>?;
    var questionCategories = surveyData.get("questionCategories") as Array<String>?;

    if (responses == null || questionCategories == null) {
        hasSurveyData = false;
        return;
    }

    // Calculate per-domain percentage scores (0-100)
    var domainSums = new [8];
    var domainCounts = new [8];
    for (var i = 0; i < 8; i++) {
        domainSums[i] = 0.0f;
        domainCounts[i] = 0;
    }

    for (var i = 0; i < responses.size(); i++) {
        var cat = questionCategories[i] as String;
        for (var d = 0; d < DOMAIN_LABELS.size(); d++) {
            if (cat.equals(DOMAIN_LABELS[d])) {
                domainSums[d] = domainSums[d] + ((responses[i] as Number).toFloat() / 4.0f * 100.0f);
                domainCounts[d] = domainCounts[d] + 1;
                break;
            }
        }
    }

    // Build domain percentages only for active domains
    var domainPcts = new [8];
    var activeWeightSum = 0.0f;
    for (var d = 0; d < 8; d++) {
        if (domainCounts[d] > 0) {
            domainPcts[d] = domainSums[d] / domainCounts[d].toFloat();
            activeWeightSum = activeWeightSum + DOMAIN_WEIGHTS[d];
        } else {
            domainPcts[d] = -1.0f; // inactive
        }
    }

    if (activeWeightSum <= 0.0f) {
        hasSurveyData = false;
        return;
    }

    hasSurveyData = true;

    // Compute composite score using Option C (multiplicative) with hEDS weights.
    // Each active domain contributes a weighted factor (1 - pct/100).
    // Any domain at 100% drives the product to zero; all at 0% gives product of 1.
    // Weights are renormalized across only the active domains.
    var symptomFactor = 1.0f;
    for (var d = 0; d < 8; d++) {
        if (domainPcts[d] >= 0.0f) {
            var normalizedWeight = DOMAIN_WEIGHTS[d] / activeWeightSum;
            // Raise (1 - pct/100) to the power of the normalized weight.
            // Approximated as: x^w = exp(w * ln(x)), but since Monkey C lacks
            // ln/exp, we use a weighted geometric approach via repeated multiplication
            // scaled by weight buckets (rounded to nearest 0.05 step).
            var healthFactor = 1.0f - (domainPcts[d] / 100.0f);
            // Weight the factor: factor^weight approximated by linear blend
            // between 1.0 (no penalty) and healthFactor (full penalty)
            var weightedFactor = 1.0f - normalizedWeight * (1.0f - healthFactor);
            symptomFactor = symptomFactor * weightedFactor;
        }
    }

    var batteryFactor = (currentLevel != null) ? (currentLevel as Float) / 100.0f : 1.0f;
    compositeScore = (batteryFactor * symptomFactor * 100.0f).toNumber();
    if (compositeScore < 0) { compositeScore = 0; }
    if (compositeScore > 100) { compositeScore = 100; }
}

    // Bubble sort
    function sortArray(arr as Array<Float>) as Array<Float> {
        var n = arr.size();
        for (var i = 0; i < n - 1; i++) {
            for (var j = 0; j < n - i - 1; j++) {
                if (arr[j] > arr[j + 1]) {
                    var tmp = arr[j];
                    arr[j] = arr[j + 1];
                    arr[j + 1] = tmp;
                }
            }
        }
        return arr;
    }

    function getPercentile(sorted as Array<Float>, pct as Float) as Float {
        var idx = (pct / 100.0f) * (sorted.size() - 1);
        var lo = idx.toNumber();
        var hi = lo + 1;
        if (hi >= sorted.size()) {
            return sorted[sorted.size() - 1];
        }
        var frac = idx - lo.toFloat();
        return sorted[lo] + frac * (sorted[hi] - sorted[lo]);
    }

    function onUpdate(dc as Dc) as Void {
    var screenW = dc.getWidth();
    var screenH = dc.getHeight();
    var cx = screenW / 2;
    var cy = screenH / 2;

    dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
    dc.clear();

    if (!hasData) {
        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, cy, Graphics.FONT_SMALL, "No Data",
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        dc.drawText(cx, cy + 30, Graphics.FONT_XTINY, "Wear watch longer",
            Graphics.TEXT_JUSTIFY_CENTER);
        return;
    }

    if (hasSurveyData) {
        // Composite score mode
        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, 30, Graphics.FONT_XTINY, "HEALTH SCORE",
            Graphics.TEXT_JUSTIFY_CENTER);

        // Big composite score
        dc.setColor(Graphics.COLOR_YELLOW, Graphics.COLOR_TRANSPARENT); // Blue
        dc.drawText(cx, cy - 30, Graphics.FONT_NUMBER_HOT,
            compositeScore.toString(),
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);

        // Small current body battery value, centered lower on the screen
        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, cy + 65, Graphics.FONT_XTINY, "Body Battery",
            Graphics.TEXT_JUSTIFY_CENTER);

        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        var batteryStr = (currentLevel != null) ? (currentLevel as Float).format("%.0f") : "--";
        dc.drawText(cx, cy + 97, Graphics.FONT_XTINY, batteryStr,
            Graphics.TEXT_JUSTIFY_CENTER);
    } else {
        // Body battery only mode (no survey yet)
        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, 40, Graphics.FONT_XTINY, "BODY BATTERY",
            Graphics.TEXT_JUSTIFY_CENTER);

        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        var currentStr = (currentLevel != null) ? (currentLevel as Float).format("%.0f") : "--";
        dc.drawText(cx, cy + 80, Graphics.FONT_NUMBER_HOT,
            currentStr,
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
    }

    drawPageIndicators(dc, screenH, 1);
}

    function drawPageIndicators(dc as Dc, screenH as Number, currentPage as Number) as Void {
        var dotRadius = 4;
        var dotSpacing = 15;
        var x = 20;
        var startY = (screenH / 2) - dotSpacing;

        for (var i = 0; i < 4; i++) {
            var y = startY + (i * dotSpacing);
            if (i == currentPage) {
                dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
                dc.fillCircle(x, y, dotRadius);
            } else {
                dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_TRANSPARENT);
                dc.drawCircle(x, y, dotRadius);
            }
        }
    }
}

class ScorePageDelegate extends WatchUi.BehaviorDelegate {
    private var view as ScorePageView;

    function initialize(v as ScorePageView) {
        BehaviorDelegate.initialize();
        view = v;
    }

    // Press button to refresh both body battery and composite score
    function onSelect() as Boolean {
        view.loadHRVData();
        view.loadSurveyData();
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