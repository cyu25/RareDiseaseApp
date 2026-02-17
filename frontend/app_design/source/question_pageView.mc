import Toybox.WatchUi;
import Toybox.Graphics;
import Toybox.Lang;
import Toybox.System;
import Toybox.Application.Storage;

class questionPageView extends WatchUi.View {
    public var value as Number;
    public var currentQuestionIndex as Number;
    public var questions as Array<String>;
    public var responses as Array<Number>;
    
    private var activeCategories as Array<String>;
    private var allQuestions as Array<String>;
    private var questionCategories as Array<String>;
    private var filteredQuestionCategories as Array<String>;
    
    public var screenW as Number;
    public var screenH as Number;
    public var decBox as Array<Number>;
    public var incBox as Array<Number>;
    public var continueBox as Array<Number>;
    public var backBox as Array<Number>;
    public var skipAllBox as Array<Number>;
    
    function initialize(checkedSymptoms as Array<String>) {
        View.initialize();
        value = 0;
        currentQuestionIndex = 0;
        screenW = 0;
        screenH = 0;
        decBox = [0,0,0,0];
        incBox = [0,0,0,0];
        continueBox = [0,0,0,0];
        backBox = [0,0,0,0];
        skipAllBox = [0,0,0,0];
        
        activeCategories = checkedSymptoms;
        questions = [];
        filteredQuestionCategories = [];
        
        // All 31 questions with category mapping per the Spider questionnaire
        allQuestions = [
            "Joint instability",                    // NMSK Q1
            "Muscle weakness",                      // NMSK Q2
            "Muscle spasms",                        // NMSK Q3
            "Balance & body position awareness problems",    // NMSK Q4
            "Tingling or loss of sensation",        // NMSK Q5
            "Joint pain",                           // Pain Q6
            "Widespread pain",                      // Pain Q7
            "Headaches or migraines",               // Pain Q8
            "Pain from mild sensations",            // Pain Q9
            "Physical tiredness",                   // Fatigue Q10
            "Mental tiredness",                     // Fatigue Q11
            "Difficulty with sleep",                // Fatigue Q12
            "Faint when moving to standing",        // Cardiac Q13
            "Faint when standing upright",          // Cardiac Q14
            "Nervous system severity",            // Cardiac Q15
            "Impact on daily life",                 // Cardiac Q16
            "Stomach bloating/pain",              // GI Q17
            "Diarrhea or constipation",             // GI Q18
            "Nausea or vomiting",                   // GI Q19
            "Reflux or difficulty swallowing",      // GI Q20
            "Full bladder sensation",               // Uro Q21
            "Urine loss",                           // Uro Q22
            "Difficulty passing urine",             // Uro Q23
            "Genital discomfort",                   // Uro Q24
            "Urinary infections",                   // Uro Q25
            "Fear of movement",                     // Anxiety Q26
            "Feeling worried or restless",          // Anxiety Q27
            "Feeling afraid",                       // Anxiety Q28
            "Feeling down or hopeless",             // Depression Q29
            "No solutions to problems",             // Depression Q30
            "Little interest in things"             // Depression Q31
        ];
        
        questionCategories = [
            "NMSK", "NMSK", "NMSK", "NMSK", "NMSK",
            "Pain", "Pain", "Pain", "Pain",
            "Fatigue", "Fatigue", "Fatigue",
            "Cardiac dysautonomia", "Cardiac dysautonomia",
            "Cardiac dysautonomia", "Cardiac dysautonomia",
            "Gastrointestinal", "Gastrointestinal",
            "Gastrointestinal", "Gastrointestinal",
            "Urogential", "Urogential", "Urogential",
            "Urogential", "Urogential",
            "Anxiety", "Anxiety", "Anxiety",
            "Depression", "Depression", "Depression"
        ];
        
        filterQuestions();

        // Always start fresh - initialize responses array
        responses = new [questions.size()];
        for (var i = 0; i < responses.size(); i++) {
            responses[i] = 0;
        }
        value = 0;
        currentQuestionIndex = 0;

    }
    
    
    function filterQuestions() as Void {
        questions = [];
        filteredQuestionCategories = [];
        
        for (var i = 0; i < allQuestions.size(); i++) {
            var category = questionCategories[i] as String;
            var isActive = false;
            for (var j = 0; j < activeCategories.size(); j++) {
                if (category.equals(activeCategories[j])) {
                    isActive = true;
                    break;
                }
            }
            if (isActive) {
                questions.add(allQuestions[i]);
                filteredQuestionCategories.add(category);
            }
        }
        
        if (questions.size() == 0) {
            questions = allQuestions;
            filteredQuestionCategories = questionCategories;
        }
    }
    
    public function getFilteredQuestionCategories() as Array<String> {
        return filteredQuestionCategories;
    }
    
    function clamp() as Void {
        if (value < 0) { value = 0; }
        if (value > 4) { value = 4; }
    }
    
    public function inc() as Void { value++; clamp(); WatchUi.requestUpdate(); }
    public function dec() as Void { value--; clamp(); WatchUi.requestUpdate(); }
    
    public function getLabelForValue(v as Number) as String {
        if (v == 0) { return "No symptom"; }
        if (v == 1) { return "Mild Impact"; }
        if (v == 2) { return "Moderate Impact"; }
        if (v == 3) { return "Marked Impact"; }
        return "Disabling";
    }
    
    public function hit(box as Array<Number>, x as Number, y as Number) as Boolean {
        if (box == null || box.size() < 4) { return false; }
        return (x >= box[0] && x <= box[0] + box[2] && y >= box[1] && y <= box[1] + box[3]);
    }
    
    public function loadResponses() as Void {
        for (var i = 0; i < responses.size(); i++) {
            var saved = Storage.getValue("response_" + i);
            if (saved != null) { responses[i] = saved as Number; }
        }
        var savedIndex = Storage.getValue("lastQuestionIndex");
        if (savedIndex != null) {
            currentQuestionIndex = savedIndex as Number;
            value = responses[currentQuestionIndex] as Number;
        }
    }
    
    public function previousQuestion() as Void {
    // Save current answer in memory (not storage)
    responses[currentQuestionIndex] = value;
    
    if (currentQuestionIndex > 0) {
        currentQuestionIndex--;
        // Load the previously answered value from memory
        value = responses[currentQuestionIndex] as Number;
        WatchUi.requestUpdate();
    }
}
    
    public function nextQuestion() as Void {
    // Save current answer in memory (not storage)
    responses[currentQuestionIndex] = value;
    
    if (currentQuestionIndex < questions.size() - 1) {
        currentQuestionIndex++;
        // Load the next question's value from memory (might be 0 or previously set)
        value = responses[currentQuestionIndex] as Number;
        WatchUi.requestUpdate();
    } else {
        // Survey complete - NOW save to storage
        SurveyStorage.saveSurveyData(responses, activeCategories, filteredQuestionCategories);
        
        var completionView = new CompletionView(responses, activeCategories, filteredQuestionCategories);
        WatchUi.pushView(completionView, new CompletionDelegate(completionView), WatchUi.SLIDE_LEFT);
    }
}
    function onUpdate(dc as Dc) as Void {
        screenW = dc.getWidth();
        screenH = dc.getHeight();
        var cx = screenW / 2;
        var cy = screenH / 2;
        
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.clear();
        
        var r = (screenW < screenH ? screenW : screenH) / 2 - 12;
        
        // Question counter
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        var titleText = "Question " + (currentQuestionIndex + 1) + "/" + questions.size();
        dc.drawText(cx, cy - r + 18, Graphics.FONT_XTINY, titleText, Graphics.TEXT_JUSTIFY_CENTER);
        
        // Question text with word wrap
        var questionY = cy - r + 50;
        var currentQuestion = questions[currentQuestionIndex] as String;
        var fontSize = Graphics.FONT_XTINY;
        if (currentQuestion.length() > 30) { questionY = cy - r + 42; }
        
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        var words = splitString(currentQuestion, " ");
        var currentLine = "";
        var lineY = questionY;
        var lineHeight = 25;
        var maxLineChars = currentQuestion.length() > 30 ? 18 : 22;
        
        for (var i = 0; i < words.size(); i++) {
            var word = words[i] as String;
            var testLine = currentLine;
            if (testLine.length() > 0) { testLine = testLine + " " + word; }
            else { testLine = word; }
            if (testLine.length() > maxLineChars && currentLine.length() > 0) {
                dc.drawText(cx, lineY, fontSize, currentLine, Graphics.TEXT_JUSTIFY_CENTER);
                lineY += lineHeight;
                currentLine = word;
            } else {
                currentLine = testLine;
            }
        }
        if (currentLine.length() > 0) {
            dc.drawText(cx, lineY, fontSize, currentLine, Graphics.TEXT_JUSTIFY_CENTER);
        }
        
        // +/- controls
        var controlsY = cy + 8;
        var leftX = cx - 70;
        var rightX = cx + 70;
        var arrowSize = 14;
        var boxW = 65;
        var boxH = 65;
        decBox = [leftX - boxW/2, controlsY - boxH/2, boxW, boxH];
        incBox = [rightX - boxW/2, controlsY - boxH/2, boxW, boxH];
        
        dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_TRANSPARENT);
        drawMinus(dc, leftX, controlsY, arrowSize);
        drawPlus(dc, rightX, controlsY, arrowSize);
        
        // Current value
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, controlsY, Graphics.FONT_LARGE, value.toString(),
                    Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        
        // Value label
        var labelText = getLabelForValue(value);
        dc.drawText(cx, cy + r - 150, Graphics.FONT_XTINY, labelText, Graphics.TEXT_JUSTIFY_CENTER);
        
        // BACK button
        var backBtnW = 75;
        var backBtnH = 40;
        var backBtnX = cx - 50;
        var backBtnY = cy + r - 80;
        backBox = [backBtnX - backBtnW/2, backBtnY - backBtnH/2, backBtnW, backBtnH];
        
        if (currentQuestionIndex > 0) {
            dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        } else {
            dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
        }
        dc.setPenWidth(2);
        dc.drawRoundedRectangle(backBtnX - backBtnW/2, backBtnY - backBtnH/2, backBtnW, backBtnH, 6);
        dc.setPenWidth(1);
        dc.drawText(backBtnX, backBtnY, Graphics.FONT_XTINY, "BACK",
                    Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        
        // NEXT/DONE button
        var btnW = 75;
        var btnH = 40;
        var btnX = cx + 50;
        var btnY = cy + r - 80;
        continueBox = [btnX - btnW/2, btnY - btnH/2, btnW, btnH];
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.setPenWidth(2);
        dc.drawRoundedRectangle(btnX - btnW/2, btnY - btnH/2, btnW, btnH, 6);
        dc.setPenWidth(1);
        var btnText = (currentQuestionIndex == questions.size() - 1) ? "DONE" : "NEXT";
        dc.drawText(btnX, btnY, Graphics.FONT_XTINY, btnText,
                    Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
    }
    
    function splitString(str as String, delimiter as String) as Array<String> {
        var result = [] as Array<String>;
        var current = "";
        for (var i = 0; i < str.length(); i++) {
            var char = str.substring(i, i + 1);
            if (char.equals(delimiter)) {
                if (current.length() > 0) { result.add(current); current = ""; }
            } else { current = current + char; }
        }
        if (current.length() > 0) { result.add(current); }
        return result;
    }
    
    function drawMinus(dc as Dc, x as Number, y as Number, size as Number) as Void {
        dc.setPenWidth(3); dc.drawLine(x - size, y, x + size, y); dc.setPenWidth(1);
    }
    function drawPlus(dc as Dc, x as Number, y as Number, size as Number) as Void {
        dc.setPenWidth(3); dc.drawLine(x - size, y, x + size, y); dc.drawLine(x, y - size, x, y + size); dc.setPenWidth(1);
    }
}

class QuestionPageDelegate extends WatchUi.BehaviorDelegate {
    private var view as questionPageView;

    function initialize(v as questionPageView) {
        BehaviorDelegate.initialize();
        view = v;
    }

    function onTap(e as ClickEvent) as Lang.Boolean {
        var c = e.getCoordinates();
        var x = c[0] as Number;
        var y = c[1] as Number;

        if (view.hit(view.decBox, x, y)) { view.dec(); return true; }
        if (view.hit(view.incBox, x, y)) { view.inc(); return true; }
        if (view.hit(view.backBox, x, y)) { view.previousQuestion(); return true; }
       // if (view.hit(view.skipAllBox, x, y)) { view.skipAllToChart(); return true; }
        if (view.hit(view.continueBox, x, y)) { view.nextQuestion(); return true; }

        return false;
    }

    function onBack() as Lang.Boolean {
        // Only allow back on the first question
        if (view.currentQuestionIndex == 0) {
            WatchUi.popView(WatchUi.SLIDE_DOWN);
            return true;
        }
        
        // Otherwise, go to previous question instead
        view.previousQuestion();
        return true;
    }
}

// =========================================================
// COMPLETION SCREEN
// =========================================================
class CompletionView extends WatchUi.View {
    private var responses as Array<Number>;
    private var activeCategories as Array<String>;
    private var questionCategories as Array<String>;
    
    function initialize(resp as Array<Number>, categories as Array<String>, qCategories as Array<String>) {
        View.initialize();
        responses = resp;
        activeCategories = categories;
        questionCategories = qCategories;
    }
    
    function onUpdate(dc as Dc) as Void {
        var screenW = dc.getWidth();
        var screenH = dc.getHeight();
        var cx = screenW / 2;
        var cy = screenH / 2;
        
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.clear();
        
        var r = (screenW < screenH ? screenW : screenH) / 2 - 12;
        
        dc.setColor(0x7B2FBE, Graphics.COLOR_TRANSPARENT);
        dc.setPenWidth(6);
        dc.drawCircle(cx, cy, r);
        dc.setPenWidth(1);
        
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.fillCircle(cx, cy, r - 4);
        
        dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_TRANSPARENT);
        drawCheckmark(dc, cx, cy - 30, 30);
        
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, cy + 40, Graphics.FONT_MEDIUM, "Nice Job!", 
                    Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        dc.drawText(cx, cy + 70, Graphics.FONT_XTINY, "Swipe up for results", 
                    Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        
    }
    
    
    function drawCheckmark(dc as Dc, x as Number, y as Number, size as Number) as Void {
        dc.setPenWidth(3);
        dc.drawCircle(x, y, size);
        dc.drawLine(x - size * 5 / 10, y, x - size * 1 / 10, y + size * 4 / 10);
        dc.drawLine(x - size * 1 / 10, y + size * 4 / 10, x + size * 6 / 10, y - size * 4 / 10);
        dc.setPenWidth(1);
    }
    
    public function getResponses() as Array<Number> { return responses; }
    public function getActiveCategories() as Array<String> { return activeCategories; }
    public function getQuestionCategories() as Array<String> { return questionCategories; }
}

class CompletionDelegate extends WatchUi.BehaviorDelegate {
    private var view as CompletionView;
    function initialize(v as CompletionView) { BehaviorDelegate.initialize(); view = v; }
    
    // function onTap(e as ClickEvent) as Lang.Boolean {
    //     WatchUi.popView(WatchUi.SLIDE_DOWN);
    //     return true;
    // }
    
    function onSwipe(evt as SwipeEvent) as Lang.Boolean {
    var direction = evt.getDirection();
    if (direction == WatchUi.SWIPE_UP) {
        var responses = view.getResponses();
        var activeCategories = view.getActiveCategories();
        var questionCategories = view.getQuestionCategories();
        var symptomLabels = [
            "NMSK",
            "Pain",
            "Fatigue",
            "Gastrointestinal",
            "Cardiac dysautonomia",
            "Urogential",
            "Anxiety",
            "Depression"
        ];
        
        // Initialize all to 0 first
        var percentageValues = new [8];
        for (var i = 0; i < 8; i++) {
            percentageValues[i] = 0;
        }
        
        // Now calculate only for active categories
        for (var c = 0; c < symptomLabels.size(); c++) {
            var categoryName = symptomLabels[c] as String;
            
            // Check if this category is active
            var isActive = false;
            for (var j = 0; j < activeCategories.size(); j++) {
                if (categoryName.equals(activeCategories[j])) {
                    isActive = true;
                    break;
                }
            }
            
            if (isActive) {
                // Calculate average for this category
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
            // If not active, it stays 0 (already initialized)
        }
        
        var dateRecorded = Time.now();
        var spiderView = new SpiderDiagramView(symptomLabels, percentageValues, dateRecorded);
        WatchUi.pushView(spiderView, new SpiderDiagramDelegate(spiderView), WatchUi.SLIDE_UP);
        return true;
    }
    return false;
}
    function onBack() as Lang.Boolean { WatchUi.popView(WatchUi.SLIDE_DOWN); return true; }
}